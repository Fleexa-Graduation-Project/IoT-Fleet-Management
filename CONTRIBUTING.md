# Contributing to Fleexa IoT Fleet Management

First off, thank you for considering contributing to Fleexa IoT Fleet Management! It's people like you that make this open-source community such a great place to learn, inspire, and create.

## How Can I Contribute?

### Reporting Bugs
If you find a bug in the source code or a mistake in the documentation, you can help us by submitting an issue to our GitHub Repository. Even better, you can submit a Pull Request with a fix!

### Suggesting Enhancements
If you have an idea for a new feature, a different device simulator, or a way to optimize our AWS rules engine, please submit an issue outlining your proposal.

### Pull Requests
We actively welcome your pull requests.

1. Fork the repo and create your branch from `dev-branch`.
2. If you've added code that should be tested, add tests.
3. If you've changed APIs, update the documentation.
4. Ensure the test suite passes (our GitHub Actions will also verify this).
5. Make sure your code lints (run `go fmt` for Go code).
6. Issue that pull request!

## Local Development Setup

To run this project locally, you'll need the following installed:
* [Docker](https://docs.docker.com/get-docker/) & Docker Compose
* [Go](https://golang.org/doc/install) (>= 1.24.2)
* [Python 3.11](https://www.python.org/downloads/)
* [Terraform](https://www.terraform.io/downloads.html)

### Running Tests Locally

**Go Backend:**
Navigate to the `backend/` directory and run:
```bash
go test ./... -v
```

**Python Simulators:**
Navigate to the repository root and run:
```bash
pip install -r devices/requirements.txt
pytest devices/tests/ -v
```

### Infrastructure Changes
If you are contributing to the Terraform configuration (`infra-iot-fleet/terraform/`), please ensure you run:
```bash
terraform fmt -recursive
terraform validate
```
Never commit your `tfstate` files or AWS credentials.

## Branch Naming Conventions
Please use the following conventions when creating a branch:
* `feature/your-feature-name`
* `fix/issue-you-are-fixing`
* `docs/documentation-update`

## Any Questions?
Feel free to open a discussion or issue. We are happy to help you get started!
