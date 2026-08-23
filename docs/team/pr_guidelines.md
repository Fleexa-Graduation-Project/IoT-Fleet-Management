# Pull Request Guidelines

This document describes what's expected of a pull request in this repository, and what
the CI pipeline in `.github/workflows/ci-cd.yml` will actually check before it can merge.

---

## Before opening a PR

* Branch from `dev-branch` (see `docs/team/development_workflow.md`), using a
  `feature/…`, `fix/…`, or `docs/…` branch name.
* Keep the PR focused on one logical change. Unrelated fixes should be their own PR — it
  makes review and, if needed, revert much easier.
* Add or update tests for any behavior change (see `docs/team/testing_strategy.md`).
* Update relevant docs if you changed a REST endpoint, an MQTT payload schema, an alert
  rule, or infrastructure — `backend/docs/` and the module READMEs should stay accurate.
* Run the same checks CI will run (formatting, linting, tests) locally first, so you're
  not relying on CI to catch avoidable failures. See `docs/team/code_standards.md` for the
  exact commands per language.

---

## What CI checks on every PR

A pull request against `main` triggers the following jobs. All of them must pass before
merge:

1. **`test` — Unit Tests & Schema Validation.** Installs Python dependencies, then runs:
   * `pytest devices/tests/unit/test_schemas.py` — validates the MQTT JSON schemas in
     `backend/docs/mqtt/schemas/`.
   * `pytest devices/tests/unit/test_sensors.py` — sensor simulator unit tests.
   * `pytest devices/tests/unit/test_actuators.py` — actuator simulator unit tests.
   * An import smoke test verifying every simulator module (`base_device`,
     `TemperatureSensor`, `LightSensor`, `GasSensor`, `DoorSensor`, `DoorLocker`,
     `ACCurtainActuator`) imports cleanly from the project root.
2. **`test-go` — Go Backend Unit Tests & Build.** Runs `go test ./... -v` and
   `go build ./...` inside `backend/`. A backend change that doesn't compile or breaks an
   existing test fails here.
3. **`build` — Build Docker Image** (depends on `test`). Builds the simulator image from
   `devices/Dockerfile` and runs a container smoke test that imports the core simulator
   modules inside the built image. This catches dependency or packaging issues that unit
   tests alone wouldn't (e.g. a missing package in the image, a broken `Dockerfile`).
4. **`terraform-plan` — Terraform Plan (Dry Run)** (depends on `test` and `test-go`, and
   only runs for pushes off `main` or a manual dispatch — practically speaking, for PR
   branches). Runs `terraform fmt -check -recursive`, `terraform validate`, and
   `terraform plan` against `infra-iot-fleet/terraform/`. If your change touches
   Terraform, read the plan output in the Actions log — this is the only chance to review
   the infrastructure diff before it's applied on merge to `main`.

The deployment jobs — **`terraform-deploy`** (Deploy Infrastructure to AWS) and
**`verify-deploy`** (Verify AWS Deployment) — only run on pushes to `main` or
`Lambda-CI/CD-Implementation`, not on PRs. They apply the Terraform plan with
`-auto-approve` and then verify the DynamoDB tables, Lambda functions, S3 buckets, and IoT
Core resources actually exist. A PR is not directly tested against these, but merging to
`main` will trigger them — so treat a merge to `main` as a deployment, not just a code
change.

---

## PR description

Include, at minimum:

* **What** changed and **why** — link the issue if one exists (see the issue templates
  under `.github/ISSUE_TEMPLATE/`).
* **Which component(s)** are affected: `backend`, `devices`, `mobile`, or
  `infra-iot-fleet`. This matches the "Environment" checklist used in the bug report
  template and helps reviewers route the PR to the right eyes.
* **How it was tested** — which test suites you ran locally, and, for infrastructure
  changes, the relevant part of the `terraform plan` output.
* Anything that needs manual verification after merge (e.g. "run the `db-export` Lambda
  once manually to confirm the new export format").

---

## Review expectations

* At least one reviewer should approve before merging. For infrastructure changes, prefer
  a reviewer who can read the Terraform plan critically — a bad `terraform apply` on merge
  to `main` affects real AWS resources.
* Don't merge with a failing or skipped required CI job. If a job is flaky (not merely
  failing due to your change), say so in the PR and get another pair of eyes before
  merging rather than re-running until it happens to pass.
* Keep the branch reasonably up to date with its base (`dev-branch` or `main`) before
  merge to avoid last-minute conflicts and to make sure CI is testing against current code.
* Squash or keep history as makes sense for the change, but keep the final commit
  message(s) descriptive — see the commit style in
  `docs/team/development_workflow.md`.

---

## After merge

* A merge to `dev-branch` runs tests/build/plan again but does not deploy.
* A merge to `main` deploys: `terraform-deploy` applies infrastructure changes, and
  `verify-deploy` checks that the expected AWS resources came up correctly. Watch the
  Actions run for your merge — if `verify-deploy` fails, don't assume the deploy is safe
  just because `terraform-deploy` succeeded.
