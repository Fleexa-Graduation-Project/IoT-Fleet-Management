# Development Workflow

This document describes how changes actually move through the Fleexa IoT Fleet
Management repository, from a local branch to a deployed AWS environment.

---

## Branching model

The repository has two long-lived branches, both wired into
`.github/workflows/ci-cd.yml`:

* **`dev-branch`** — the active development branch. This is the branch you fork/branch
  from for day-to-day work (see `CONTRIBUTING.md`). Pushes to `dev-branch` run the test,
  build, and Terraform-plan jobs, but do **not** deploy to AWS.
* **`main`** — the stable, deployed branch. A push to `main` runs the full pipeline,
  including `terraform-deploy` and `verify-deploy`, which apply infrastructure changes and
  verify the live AWS environment (DynamoDB tables, Lambda functions, S3 buckets, IoT Core
  rules and things).

There is also a third branch referenced directly in the CI/CD workflow's deploy
conditions: **`Lambda-CI/CD-Implementation`**. Like `main`, a push to this branch also
triggers `terraform-deploy` and `verify-deploy`. Treat it as a second production-equivalent
branch — don't push to it casually, and be aware that anything landing there gets applied
to real AWS infrastructure.

Pull requests are only validated against `main` (`pull_request: branches: [main]`) —
opening a PR into `main` runs the unit tests, Go tests, Docker build validation, and a
Terraform plan (dry run, no apply).

### Feature branches

Per `CONTRIBUTING.md`, branch names should describe the change:

* `feature/your-feature-name` — new functionality
* `fix/issue-you-are-fixing` — bug fixes
* `docs/documentation-update` — documentation-only changes

Branch from `dev-branch`, not `main`.

---

## Day-to-day workflow

1. **Fork and branch.** Fork the repository, then create your branch from `dev-branch`:
   ```bash
   git checkout dev-branch
   git pull
   git checkout -b feature/your-feature-name
   ```
2. **Set up locally.** Depending on what you're touching:
   * Go backend: `cd backend && go mod download`
   * Python simulators: `pip install -r devices/requirements.txt`
   * Terraform: have Terraform >= 1.14.0 installed
   * Mobile: `cd mobile && flutter pub get`
3. **Make your change**, keeping it scoped to one logical piece of work.
4. **Add or update tests.** See `docs/team/testing_strategy.md` — untested behavior
   changes are one of the more common reasons a PR gets sent back for revisions.
5. **Run the checks you'd expect CI to run**, locally, before pushing:
   ```bash
   # Go backend
   cd backend && go fmt ./... && go vet ./... && go test ./... -v

   # Python simulators
   black devices/ && flake8 && pylint devices/simulators
   pytest devices/tests/ -v

   # Terraform
   cd infra-iot-fleet/terraform && terraform fmt -recursive && terraform validate
   ```
6. **Update documentation** if you changed an API, a schema, or user-facing behavior —
   the backend's REST API and MQTT schemas are documented under `backend/docs/`.
7. **Commit** with a clear message describing the change (see commit style below).
8. **Push your branch** and open a pull request against the appropriate base — normally
   `dev-branch`, unless the change is a hotfix intended for immediate release. See
   `docs/team/pr_guidelines.md` for what CI will check.
9. **Address review feedback** and keep the branch up to date with its base until it's
   merged.

---

## Commit style

Keep commits scoped and descriptive — a reviewer or future contributor should be able to
tell what changed and why from the message alone, e.g.:

```
fix(simulators): comment out redundant boto3 simulator to prevent telemetry and alert spam
feat(simulators): adjust gas leak interval/curve and add DOOR_LEFT_UNLOCKED / DOOR_LEFT_OPEN alerts
```

A `type(scope): summary` prefix (`feat`, `fix`, `docs`, `refactor`, `chore`, matching the
affected area — `simulators`, `backend`, `mobile`, `infra`) is the convention already used
throughout this repository's history; keep using it for consistency.

---

## Infrastructure changes

Changes under `infra-iot-fleet/terraform/` follow the same branch/PR flow, but with extra
care because they affect real AWS resources once merged to `main` or
`Lambda-CI/CD-Implementation`:

* Always run `terraform fmt -recursive` and `terraform validate` locally first.
* Every PR against `main` automatically gets a `terraform plan` from CI — read the plan
  output in the Actions log before approving or merging.
* Never commit `.tfstate` files or AWS credentials.
* Because `terraform-deploy` runs with `-auto-approve` on `main`, a merge to `main` is
  effectively an infrastructure deployment — treat it with the same care as a production
  release.

---

## Local environment

For running the simulators against a real (or LocalStack) AWS backend, copy
`devices/.env.example` to `devices/.env` and provide AWS credentials, then:

```bash
cd devices
docker compose up --build -d
docker compose logs -f
```

`.env` files are git-ignored — never commit credentials.
