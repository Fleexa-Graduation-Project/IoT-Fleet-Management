---
name: Bug Report
about: Report a problem with the backend, device simulators, mobile app, or infrastructure
title: "[Bug]: "
labels: ["bug", "triage"]
assignees: []
---

## Description

<!-- A clear and concise description of what the bug is. -->

## Steps to Reproduce

<!-- Steps to reproduce the behavior, as specifically as possible. -->

1. Go to '...'
2. Run '...'
3. Trigger '...'
4. See error

## Expected Behavior

<!-- What you expected to happen. -->

## Actual Behavior

<!-- What actually happened instead. -->

## Environment

<!-- Check the component(s) affected. -->

- [ ] `backend` (Go Lambdas: `api-service`, `iot-ingestion`, `door-watch`, `ac-timer-watch`, `db-export`)
- [ ] `devices` (Python simulators / MQTT / AWS IoT Core)
- [ ] `mobile` (Flutter app)
- [ ] `infra-iot-fleet` (Terraform / AWS infrastructure)
- [ ] Other: <!-- specify -->

**Relevant versions / setup:**

- Go version (if backend):
- Python version (if devices):
- Flutter/Dart version (if mobile):
- Terraform version (if infra):
- OS / Docker version:
- Branch / commit SHA:

## Logs / Screenshots

<!-- Paste relevant logs (e.g. `docker compose logs -f`, Lambda CloudWatch logs, `flutter run` output)
     or attach screenshots. Wrap logs in a code block for readability. -->

```
paste logs here
```

## Additional Context

<!-- Anything else that would help diagnose the issue (recent changes, related PRs, etc.). -->
