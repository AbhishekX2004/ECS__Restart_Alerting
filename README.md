# ECS Monitoring & Alerting Terraform Module

This Terraform module provides a flexible way to set up monitoring and alerting for AWS ECS (Fargate) Services based on container restart counts. It provisions a CloudWatch Alarm that triggers an SNS email notification when containers within an ECS task crash repeatedly.

## Features

This module handles two distinct use cases seamlessly:

1. **Deploying a new ECS Cluster & Service:** Provision a brand new Fargate service with Container Insights enabled, a CloudWatch Log group, an execution role, and the required metrics alarm.
2. **Monitoring an Existing ECS Service:** Attach the SNS email alerting and CloudWatch Alarm directly to an already running ECS cluster and service, without provisioning duplicate infrastructure.

---

## How to Use

### 1. Initialize Terraform
Before running any configuration, initialize the working directory:
```bash
terraform init
```

### 2. Configure `terraform.tfvars`

#### Scenario A: Monitor an *Existing* ECS Cluster and Service
To apply alerting to resources that are already running in AWS (e.g., `monitoring-test-cluster` & `crashing-service`), use the following variables:

```hcl
use_existing_cluster = true
use_existing_service = true

ecs_cluster_name     = "monitoring-test-cluster"
ecs_service_name     = "crashing-service"

alert_email          = "your.email@example.com"
```

#### Scenario B: Create a *New* ECS Cluster and Service
To provision entirely new resources alongside the alerting setup, set the toggles to false and define the constraints:

```hcl
use_existing_cluster = false
use_existing_service = false

project_name         = "my-app"
ecs_task_cpu         = "256"
ecs_task_memory      = "512"

alert_email          = "your.email@example.com"
```

### 3. Deploy
Review the planned infrastructure changes and apply them:
```bash
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

---

## Critical Cases & Gotchas

When attaching this module to an **existing ECS service**, ensure the following requirements are met to guarantee successful alarm triggers:

1. **Confirm SNS Subscription**: After applying Terraform, check the `alert_email` inbox for a "AWS Notification - Subscription Confirmation" email. You must click the confirmation link, or alerts will be silently dropped.
2. **Enable Container Insights**: Ensure the existing ECS cluster has "Container Insights" enabled in the AWS Console. If disabled, the `RestartCount` metric is never emitted.
3. **Configure Restart Policies**: Ensure the existing Task Definition has a **Container restart policy** enabled. If missing, Fargate will silently kill crashing tasks instead of incrementing `RestartCount`. (Note: This module automatically adds this policy when creating *new* task definitions).
