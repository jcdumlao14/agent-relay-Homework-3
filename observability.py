from __future__ import annotations

import json
import logging
import os
import sys
import time
from typing import Any

from fastapi import FastAPI, Request
from opentelemetry import metrics, trace
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor

SERVICE_NAME = os.getenv("OTEL_SERVICE_NAME", "agent-relay")
SERVICE_VERSION = os.getenv("OTEL_SERVICE_VERSION", "0.1.0")
OTEL_ENABLED = os.getenv("OTEL_ENABLED", "false").lower() == "true"
OTEL_EXPORTER_OTLP_ENDPOINT = os.getenv(
    "OTEL_EXPORTER_OTLP_ENDPOINT",
    "http://otel-collector:4318",
)


class JsonFormatter(logging.Formatter):
    """Structured JSON logging without request secrets or bodies."""

    def format(self, record: logging.LogRecord) -> str:
        span = trace.get_current_span()
        span_context = span.get_span_context()

        trace_id = ""
        span_id = ""

        if span_context.is_valid:
            trace_id = format(span_context.trace_id, "032x")
            span_id = format(span_context.span_id, "016x")

        payload: dict[str, Any] = {
            "timestamp": self.formatTime(
                record,
                "%Y-%m-%dT%H:%M:%S",
            ),
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
            "service": SERVICE_NAME,
            "version": SERVICE_VERSION,
        }

        if trace_id:
            payload["trace_id"] = trace_id

        if span_id:
            payload["span_id"] = span_id

        extra_fields = (
            "http_method",
            "http_route",
            "http_status",
            "duration_ms",
        )

        for field in extra_fields:
            value = getattr(record, field, None)
            if value is not None:
                payload[field] = value

        return json.dumps(payload, ensure_ascii=False)


def configure_logging() -> None:
    """Configure application-wide structured JSON logging."""

    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(JsonFormatter())

    root = logging.getLogger()

    # Avoid duplicate handlers if the application is initialized more
    # than once during tests or development.
    root.handlers.clear()
    root.addHandler(handler)
    root.setLevel(logging.INFO)


def configure_tracing() -> None:
    """Configure OTLP tracing only when explicitly enabled."""

    if not OTEL_ENABLED:
        return

    resource = Resource.create(
        {
            "service.name": SERVICE_NAME,
            "service.version": SERVICE_VERSION,
        }
    )

    provider = TracerProvider(resource=resource)

    from opentelemetry.exporter.otlp.proto.http.trace_exporter import (
        OTLPSpanExporter,
    )

    exporter = OTLPSpanExporter(
        endpoint=(
            f"{OTEL_EXPORTER_OTLP_ENDPOINT.rstrip('/')}"
            "/v1/traces"
        )
    )

    provider.add_span_processor(
        BatchSpanProcessor(exporter)
    )

    trace.set_tracer_provider(provider)


def configure_metrics() -> None:
    """Configure OTLP metrics only when explicitly enabled."""

    if not OTEL_ENABLED:
        return

    resource = Resource.create(
        {
            "service.name": SERVICE_NAME,
            "service.version": SERVICE_VERSION,
        }
    )

    from opentelemetry.exporter.otlp.proto.http.metric_exporter import (
        OTLPMetricExporter,
    )
    from opentelemetry.sdk.metrics import MeterProvider
    from opentelemetry.sdk.metrics.export import (
        PeriodicExportingMetricReader,
    )

    exporter = OTLPMetricExporter(
        endpoint=(
            f"{OTEL_EXPORTER_OTLP_ENDPOINT.rstrip('/')}"
            "/v1/metrics"
        )
    )

    reader = PeriodicExportingMetricReader(exporter)

    provider = MeterProvider(
        resource=resource,
        metric_readers=[reader],
    )

    metrics.set_meter_provider(provider)


def configure_observability(app: FastAPI) -> None:
    """
    Configure logs, traces, and metrics.

    OTLP export remains disabled unless OTEL_ENABLED=true.

    Telemetry deliberately excludes:
    - request bodies
    - authorization headers
    - cookies
    - query strings
    - database URLs
    - task contents
    - agent credentials
    - claim tokens
    """

    configure_logging()
    configure_tracing()
    configure_metrics()

    tracer = trace.get_tracer("agent-relay.http")
    meter = metrics.get_meter("agent-relay.http")

    http_requests = meter.create_counter(
        "agent_relay_http_requests_total",
        description="Total HTTP requests handled by Agent Relay.",
        unit="1",
    )

    claim_errors = meter.create_counter(
        "agent_relay_claim_errors_total",
        description="Total 5xx responses from the task claim endpoint.",
        unit="1",
    )

    http_duration = meter.create_histogram(
        "agent_relay_http_request_duration_ms",
        description="HTTP request duration in milliseconds.",
        unit="ms",
    )

    logger = logging.getLogger("agent_relay.http")

    @app.middleware("http")
    async def observability_middleware(
        request: Request,
        call_next,
    ):
        start = time.perf_counter()

        with tracer.start_as_current_span(
            f"{request.method} {request.url.path}"
        ) as span:
            span.set_attribute(
                "http.request.method",
                request.method,
            )
            span.set_attribute(
                "url.path",
                request.url.path,
            )

            status_code = 500

            try:
                response = await call_next(request)
                status_code = response.status_code
                return response

            finally:
                duration_ms = round(
                    (time.perf_counter() - start) * 1000,
                    2,
                )

                route = request.scope.get("route")
                route_path = getattr(route, "path", None)

                if not route_path:
                    route_path = request.url.path

                span.set_attribute(
                    "http.route",
                    route_path,
                )

                span.set_attribute(
                    "http.response.status_code",
                    status_code,
                )

                status_class = f"{status_code // 100}xx"

                attributes = {
                    "http_method": request.method,
                    "http_route": route_path,
                    "status_class": status_class,
                }

                http_requests.add(
                    1,
                    attributes=attributes,
                )

                http_duration.record(
                    duration_ms,
                    attributes=attributes,
                )

                if (
                    request.method == "POST"
                    and route_path == "/api/v1/tasks/claim"
                    and status_code >= 500
                ):
                    claim_errors.add(
                        1,
                        attributes={
                            "http_method": request.method,
                            "http_route": route_path,
                        },
                    )

                logger.info(
                    "http_request",
                    extra={
                        "http_method": request.method,
                        "http_route": route_path,
                        "http_status": status_code,
                        "duration_ms": duration_ms,
                    },
                )
