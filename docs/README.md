# Fleexa Documentation

This folder is the documentation home for the Fleexa IoT Fleet Management platform. Start with the root [`README.md`](../README.md) for the project overview, then use the sections below to go deeper.

## [`api/`](./api/)
REST and realtime API reference for the Go backend: [`endpoints.md`](./api/endpoints.md) documents every route under `/api/v1`, [`openapi.yaml`](./api/openapi.yaml) is the machine-readable spec, [`websocket.md`](./api/websocket.md) covers realtime push behavior, and [`examples/`](./api/examples/) holds worked request/response samples for listing devices, sending commands, and querying telemetry.

## [`architecture/`](./architecture/)
How the system fits together: [`system_architecture.md`](./architecture/system_architecture.md) (overall component map), [`data_flow.md`](./architecture/data_flow.md) (device-to-dashboard data path), [`deployment_architecture.md`](./architecture/deployment_architecture.md) (AWS resources and Lambda topology), and [`security_model.md`](./architecture/security_model.md) (mTLS, Cognito, and IAM boundaries).

## [`guides/`](./guides/)
Task-oriented guides for contributors: [`onboarding.md`](./guides/onboarding.md) (new contributor setup), [`deployment.md`](./guides/deployment.md) (shipping infrastructure and code changes), [`troubleshooting.md`](./guides/troubleshooting.md) (fixes for common failures), and [`faq.md`](./guides/faq.md) (project background and design decisions).

## [`setup/`](./setup/)
Environment setup instructions: [`aws_setup.md`](./setup/aws_setup.md) (provisioning the AWS account and infrastructure), [`docker_guide.md`](./setup/docker_guide.md) (running the device simulator fleet), and [`local_development.md`](./setup/local_development.md) (running the backend, simulators, and mobile app on your machine).

## [`team/`](./team/)
Team process documentation: [`code_standards.md`](./team/code_standards.md) (formatting and style conventions), [`development_workflow.md`](./team/development_workflow.md) (branching and review flow), [`pr_guidelines.md`](./team/pr_guidelines.md) (what a good pull request looks like), and [`testing_strategy.md`](./team/testing_strategy.md) (how each part of the stack is tested).

## [`assets/`](./assets/)
Static images referenced throughout this documentation and the top-level READMEs, including the Fleexa logos, the architecture diagram (`architecture.gif`), and the DynamoDB schema diagram (`database_schema.svg`).
