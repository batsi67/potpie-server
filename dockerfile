FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

# System deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl git supervisor \
  && rm -rf /var/lib/apt/lists/*

# Install uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:${PATH}"

# ✅ Copy ONLY dependency files first (for cache)
COPY requirements.fly.txt /app/requirements.fly.txt

# ✅ Install heavy deps before app code (cached unless requirements change)
RUN uv pip install --system --index-url https://download.pytorch.org/whl/cpu "torch==2.9.1" \
 && uv pip install --system -r /app/requirements.fly.txt \
 && rm -rf /root/.cache /tmp/*

# Supervisor confs
COPY supervisord.server.conf /etc/supervisor/conf.d/server.conf
COPY supervisord.worker.conf /etc/supervisor/conf.d/worker.conf

# Copy app code last
COPY . /app

EXPOSE 8001

# Default process (Fly will override via fly.toml [processes])
CMD ["supervisord", "-n", "-c", "/etc/supervisor/conf.d/server.conf"]
