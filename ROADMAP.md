# Project Roadmap

This roadmap outlines the past achievements, current work, and future vision for the **Fleexa IoT Fleet Management** platform. Note that this is a living document and priorities may shift based on community feedback.

## Phase 1: Foundation (Completed) ✅
- [x] Establish Go backend architecture and folder structure.
- [x] Create Python-based device simulators (Temperature, Door, Gas).
- [x] Implement AWS Infrastructure as Code (Terraform) for API Gateway, Lambda, IoT Core, and DynamoDB.
- [x] Bi-directional MQTT connectivity using X.509 mTLS certificates.
- [x] Basic alerting logic (Threshold breaches).
- [x] Automated CI/CD pipelines (GitHub Actions).

## Phase 2: Advanced Intelligence & UI (Current) 🚧
- [x] Dynamic AWS User generation and association from DynamoDB.
- [x] Escalating Alerts Engine (Time-decay algorithms for open doors).
- [ ] Complete Flutter Mobile Application for Real-Time monitoring.
- [ ] Real-time WebSocket connection to API Gateway for instant dashboard updates.
- [ ] Over-the-Air (OTA) firmware update orchestration for physical devices.
- [ ] User role-based access control (RBAC) via Cognito Custom Attributes.

## Phase 3: Analytics & Machine Learning (Future) 🔮
- [ ] AWS Athena and QuickSight integration with our S3 Data Lake for business intelligence dashboards.
- [ ] Predictive Maintenance: Machine Learning models to predict device failure (e.g., HVAC breakdowns) based on historical telemetry.
- [ ] Edge Compute: Migrating simple rules from cloud lambdas directly to AWS IoT Greengrass edge nodes.
- [ ] Multi-region active-active deployment using DynamoDB Global Tables.
- [ ] Geo-fencing: Automated triggers based on mobile device proximity to the physical smart assets.

## How to get involved?
Check out our [CONTRIBUTING.md](CONTRIBUTING.md) to see how you can help us achieve the items in Phase 2 and Phase 3!
