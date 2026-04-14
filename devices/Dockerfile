FROM python:3.11-slim

WORKDIR /app

# Copy root requirements and sub-requirements
COPY requirements.txt .
COPY backend/requirements.txt ./backend/
COPY devices/requirements.txt ./devices/

RUN pip install --no-cache-dir -r requirements.txt

# Copy required directories for the simulator
COPY backend/docs/mqtt/schemas/ ./backend/docs/mqtt/schemas/
COPY devices/ ./devices/
COPY orchestrator.py .

# Certs mounted at runtime — never bake into image
VOLUME ["/app/certs"]

ENV PYTHONUNBUFFERED=1

CMD ["python", "-u", "orchestrator.py"]
