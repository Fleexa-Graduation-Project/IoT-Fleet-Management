.PHONY: install lint format test docker-up docker-down tf-plan tf-apply help

help:
	@echo "Fleexa IoT Fleet Management — common tasks"
	@echo ""
	@echo "  make install     Install dev dependencies (requirements-dev.txt)"
	@echo "  make lint        Run flake8 + pylint over devices/ and orchestrator.py"
	@echo "  make format      Run black over the repo"
	@echo "  make test        Run the pytest suite (devices/tests)"
	@echo "  make docker-up   Build and start the device simulators (devices/)"
	@echo "  make docker-down Stop the device simulators"
	@echo "  make tf-plan     terraform plan (infra-iot-fleet/terraform)"
	@echo "  make tf-apply    terraform apply (infra-iot-fleet/terraform)"

install:
	pip install -r requirements-dev.txt

lint:
	flake8 .
	pylint devices orchestrator.py

format:
	black .

test:
	pytest

docker-up:
	cd devices && docker compose up --build -d

docker-down:
	cd devices && docker compose down

tf-plan:
	cd infra-iot-fleet/terraform && terraform plan -var="aws_region=us-east-1"

tf-apply:
	cd infra-iot-fleet/terraform && terraform apply -var="aws_region=us-east-1"
