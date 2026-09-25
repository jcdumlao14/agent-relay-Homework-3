FROM python:3.11-slim

WORKDIR /app

# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Copy dependency definitions first for Docker layer caching
COPY pyproject.toml uv.lock ./

# Install project dependencies without development dependencies
RUN uv sync --frozen --no-dev

# Copy Agent Relay application
COPY main.py database.py storage.py schemas.py errors.py dashboard.py worker.py observability.py ./
COPY dashboard.html ./
COPY SPEC.md README.md ./

# Create an unprivileged application user.
RUN useradd --create-home --shell /usr/sbin/nologin appuser && chown -R appuser:appuser /app

# Make the virtual environment the default PATH
ENV PATH="/app/.venv/bin:$PATH"

# Agent Relay listens on all interfaces inside the container
EXPOSE 8000

# Run the application without root privileges.
USER 1000:1000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
