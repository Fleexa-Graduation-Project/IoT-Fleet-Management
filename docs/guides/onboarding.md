# Contributor Onboarding

Welcome to **Fleexa IoT Fleet Management**. This guide gets a new contributor from zero to a running local environment.

## 1. Get Access

1. Ask a maintainer to add you as a collaborator on the [`Fleexa-Graduation-Project/IoT-Fleet-Management`](https://github.com/Fleexa-Graduation-Project/IoT-Fleet-Management) GitHub repository.
2. If you'll be deploying infrastructure (rather than just reading code or running simulators against an existing AWS account), ask for:
   - AWS IAM credentials (access key + secret) for the shared development account, or your own sandbox account (see [`setup/aws_setup.md`](../setup/aws_setup.md)).
   - The `devices/.env` values used by the team (AWS region, and optionally a shared `MQTT_BROKER` endpoint), shared through a private channel — never through git.
3. Clone the repository:
   ```bash
   git clone https://github.com/Fleexa-Graduation-Project/IoT-Fleet-Management.git
   cd IoT-Fleet-Management
   ```

## 2. Understand the Repository Layout

The project is a monorepo split by runtime. From the root [`README.md`](../../README.md#repository-structure):

```text
IoT-Fleet-Management/
├── backend/                  # Go microservices and rules engine
│   ├── cmd/                  # Entrypoints (api-service, door-watch, iot-ingestion)
│   ├── docs/                 # Architecture, database, and API documentation
│   ├── internal/             # Core domain logic (alerts, telemetry, users, auth)
│   ├── models/               # Shared data models and structs
│   └── pkg/                  # Shared utilities (db, logger)
├── design/                   # UI/UX design assets, wireframes, and fonts
├── devices/                  # Python device simulators
│   ├── certs/                # X.509 device certificates for AWS IoT Core mTLS
│   ├── simulators/           # Python simulation scripts (sensors and actuators)
│   └── tests/                # Unit and integration tests for simulators
├── docs/                     # General project documentation and setup guides
├── infra-iot-fleet/          # AWS Infrastructure as Code
│   └── terraform/            # Terraform modules (api_gateway, cognito, dynamodb)
├── mobile/                   # Flutter mobile application
│   ├── lib/                  # Source code (providers, screens, services, widgets)
│   └── test/                 # Mobile application tests
├── monitoring/               # CloudWatch dashboards and logging configurations
├── .github/workflows/        # Automated CI/CD pipelines
└── README.md                 # Project overview
```

Each major directory has its own README with more detail: [`backend/README.md`](../../backend/README.md), [`devices/README.md`](../../devices/README.md), [`mobile/README.md`](../../mobile/README.md).

A rough mental model of "who owns what":
- **`backend/`** — five independent Go Lambda functions (`api-service`, `iot-ingestion`, `door-watch`, `ac-timer-watch`, `db-export`) sharing common `internal/` packages.
- **`devices/`** — Dockerized Python processes that impersonate real hardware over MQTT/mTLS.
- **`infra-iot-fleet/terraform/`** — the only source of truth for what exists in AWS.
- **`mobile/`** — the Flutter client end users install.

## 3. Install Prerequisites

Install whichever of these you need for the part of the stack you'll be working on (root [README "Getting Started"](../../README.md#getting-started)):

| Tool | Version | Needed for |
| :--- | :--- | :--- |
| [AWS CLI v2](https://aws.amazon.com/cli/) | latest, configured with credentials | Any AWS interaction, Terraform |
| [Terraform](https://www.terraform.io/downloads.html) | >= 1.14.0 | Provisioning/changing infrastructure |
| [Docker & Docker Compose](https://docs.docker.com/get-docker/) | recent | Running the device simulator fleet |
| [Go](https://golang.org/doc/install) | >= 1.24.2 | Backend Lambda development |
| [Python](https://www.python.org/downloads/) | 3.11 | Simulator development, running simulators outside Docker |
| [Flutter SDK](https://docs.flutter.dev/get-started/install) | >= 3.0.0 | Mobile app development |

You do not need every tool on day one — a backend contributor mostly needs Go and AWS CLI; a simulator contributor mostly needs Python and Docker; a mobile contributor mostly needs Flutter.

## 4. First Steps Locally

1. **Read the architecture docs** in [`docs/architecture/`](../architecture/) and the [Device Catalog](../../README.md#device-catalog) in the root README to understand what a "device" means in this system.
2. **Pick a starting point** based on what you'll work on, and follow the matching guide in [`docs/setup/`](../setup/):
   - Backend Go code → [`local_development.md`](../setup/local_development.md) (`go build`, `go test ./...`).
   - Device simulators → [`docker_guide.md`](../setup/docker_guide.md) to run the full fleet in Docker, or [`local_development.md`](../setup/local_development.md) to run/test them with plain `pytest`.
   - Mobile app → [`local_development.md`](../setup/local_development.md) (`flutter pub get && flutter run`).
   - Infrastructure changes → [`../setup/aws_setup.md`](../setup/aws_setup.md) and [`deployment.md`](./deployment.md).
3. **Run the test suites** before making changes, so you have a known-good baseline:
   ```bash
   # Backend
   cd backend && go test ./...

   # Simulators (from repo root)
   pip install -r requirements-dev.txt
   pytest
   ```
4. **Make a small change** and open a pull request against `dev-branch` (see [`team/pr_guidelines.md`](../team/pr_guidelines.md) and [`team/development_workflow.md`](../team/development_workflow.md)) — this is the fastest way to confirm your environment and CI access both work.

## 5. Where to Ask Questions

- Check [`troubleshooting.md`](./troubleshooting.md) first — it covers the recurring issues (mTLS certs, Terraform, Firebase credentials, Cognito 401s, DynamoDB throttling).
- Check [`faq.md`](./faq.md) for "why" questions about the project's design choices.
- Everything else — ask in the team channel or open a discussion on the repository.
