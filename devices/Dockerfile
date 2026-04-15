FROM python:3.11-slim

WORKDIR /app

COPY devices/requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Maintain structure for modules and relative schema path
COPY devices/simulators/ ./devices/simulators/
COPY backend/docs/mqtt/schemas/ ./backend/docs/mqtt/schemas/
COPY orchestrator.py .

RUN mkdir -p logs

# Certs mounted at runtime — never bake into image
VOLUME ["/app/certs"]

ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/app
ENV MQTT_BROKER=localhost

CMD ["python", "-u", "orchestrator.py"]