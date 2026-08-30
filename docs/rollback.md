# Rollback Procedure

## Overview

The application is deployed on an AWS EC2 instance using Docker.
Docker images are stored in Amazon ECR.

Deployment flow:

GitHub Actions
    ↓
Build Docker Image
    ↓
Push Image to Amazon ECR
    ↓
AWS SSM
    ↓
EC2
    ↓
Docker Container
    ↓
Health Check

## Rollback Objective

If a newly deployed version causes application failure,
the previous working Docker image should be restored.

## Current Deployment

ECR Repository:

react-devops

AWS Region:

ap-south-1

Application Container:

react-app

Application Port:

8080

## Rollback Steps

### 1. Check running container

```bash
docker ps
