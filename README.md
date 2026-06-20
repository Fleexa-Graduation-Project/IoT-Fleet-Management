# 🌐 Fleexa IoT Fleet Management

[![CI/CD](https://github.com/Fleexa-Graduation-Project/IoT-Fleet-Management/actions/workflows/ci-cd.yml/badge.svg?branch=dev-branch)](https://github.com/Fleexa-Graduation-Project/IoT-Fleet-Management/actions/workflows/ci-cd.yml)
[![Terraform](https://img.shields.io/badge/Terraform-1.14.8-623CE4.svg?logo=terraform)](https://www.terraform.io/)
[![Go](https://img.shields.io/badge/Go-1.24.2-00ADD8.svg?logo=go)](https://golang.org/)
[![AWS](https://img.shields.io/badge/AWS-IoT_Core_%7C_Lambda_%7C_DynamoDB-232F3E.svg?logo=amazon-aws)](https://aws.amazon.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A highly scalable, real-time IoT fleet management platform designed to monitor, analyze, and control smart devices at scale. Built with a high-performance Go backend, Python-based dynamic device simulators, and entirely provisioned on AWS using Terraform.

---

## 🏗️ Architecture Overview

<!-- 
  TODO: Replace this placeholder with an exported GIF of your Draw.io architecture diagram!
  Ensure the image path points to a valid file inside your repository. 
-->
![Architecture Diagram](https://raw.githubusercontent.com/Fleexa-Graduation-Project/IoT-Fleet-Management/main/docs/assets/architecture-placeholder.png)

### The Flow
1. **Edge Simulation**: Dockerized Python simulators generate dynamic telemetry (temperature, gas levels, door states) and authenticate with AWS IoT Core using mutual TLS (mTLS).
2. **Ingestion & Rules**: AWS IoT Core routes telemetry and alerts to specialized AWS Lambda processors written in Go.
3. **Data Storage**: Processed data is stored in partitioned DynamoDB tables (`Telemetry`, `Device State`, `Alerts`, `Commands`, `Users`).
4. **Data Lake**: Aggregated data is routed to an Amazon S3 Data Lake for long-term storage and analytical queries.
5. **API & Client**: An API Gateway exposes endpoints secured by Amazon Cognito, enabling cross-platform mobile/web clients (e.g., Flutter) to fetch real-time overviews and control actuators.

---

## ✨ Core Features

* 🚀 **Real-Time Telemetry & Control**: Bi-directional MQTT communication between edge devices and the cloud.
* 🚨 **Escalating Alerts Engine**: Smart alerting rules (e.g., Door left open for 1m, 2m, 4m... triggers escalating notifications).
* 🔄 **Dynamic User Simulation**: Simulators automatically authenticate with AWS to dynamically scan DynamoDB for authorized users to associate simulated data with real users.
* 🛠️ **Infrastructure as Code (IaC)**: Zero-click environment replication via robust Terraform modules.
* ☁️ **Serverless First**: Powered entirely by AWS managed services (IoT Core, Lambda, API Gateway, DynamoDB) minimizing operational overhead.

---

## 📂 Repository Structure

```text
IoT-Fleet-Management/
├── backend/                  # Go microservices, lambda processors, rules engine
├── devices/                  # Python device simulators, Dockerfiles, MQTT schemas
├── infra-iot-fleet/          # Terraform configurations & AWS IaC modules
├── .github/workflows/        # CI/CD pipelines (Testing, Build, TF Deploy)
└── README.md                 # You are here!
```

---

## 🚀 Getting Started

Follow these instructions to get a copy of the project up and running in your own AWS environment.

### Prerequisites
* [AWS CLI v2](https://aws.amazon.com/cli/) configured with Administrator credentials.
* [Terraform](https://www.terraform.io/downloads.html) (>= 1.14.0)
* [Docker & Docker Compose](https://docs.docker.com/get-docker/)
* [Go](https://golang.org/doc/install) (>= 1.24.2)
* [Python 3.11](https://www.python.org/downloads/) (for local simulator debugging)

### 1. Infrastructure Deployment (AWS)

1. Navigate to the Terraform directory:
   ```bash
   cd infra-iot-fleet/terraform
   ```
2. Initialize and apply the Terraform configuration:
   ```bash
   terraform init
   terraform apply -var="aws_region=us-east-1"
   ```
3. Once applied, Terraform will output your new AWS IoT Core Endpoint, API Gateway URL, and Cognito User Pool IDs.

### 2. Running the Device Simulators (Docker)

Our simulators dynamically generate telemetry and act upon cloud commands.

1. Ensure your AWS credentials are exported in your terminal so the simulators can dynamically fetch test users from DynamoDB:
   ```bash
   export AWS_ACCESS_KEY_ID="your-access-key"
   export AWS_SECRET_ACCESS_KEY="your-secret-key"
   export AWS_REGION="us-east-1"
   
   # Optional: Set a specific user pool if the dynamic fetch fails
   export USER_IDS="uuid1,uuid2"
   ```
2. Build and start the simulator containers:
   ```bash
   cd devices
   docker compose up --build -d
   ```
3. View the live simulator logs:
   ```bash
   docker compose logs -f
   ```

---

## 🤖 CI/CD Pipeline

This project uses **GitHub Actions** for continuous integration and continuous deployment.

1. **Test Job**: Runs `go test` and Python `pytest` for schema validations across the codebase.
2. **Build Job**: Builds the Docker images for the edge simulators to ensure no regressions occur.
3. **Terraform Plan**: Generates an execution plan on Pull Requests.
4. **Terraform Deploy**: Automatically provisions the infrastructure on AWS when pushing to the `main` or `Lambda-CI/CD-Implementation` branches.
5. **Verify Job**: Validates the cloud environment by dynamically verifying that all required DynamoDB tables, Lambda Functions, and S3 Buckets exist and are healthy.

---

## 📝 License
This project is licensed under the MIT License - see the LICENSE file for details.