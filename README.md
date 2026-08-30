# React AWS DevOps Project

A complete DevOps project demonstrating the deployment of a React application on AWS using Docker, Amazon ECR, Amazon EC2, AWS Systems Manager (SSM), GitHub Actions, GitHub OIDC and Terraform.

## 1. Project Overview

Whenever code is pushed to `main`, GitHub Actions:
1. Checks out source code
2. Installs dependencies
3. Runs lint checks
4. Authenticates with AWS using GitHub OIDC
5. Builds the Docker image
6. Pushes the image to Amazon ECR
7. Finds the running EC2 instance
8. Deploys using AWS SSM
9. Starts the React container
10. Performs an application health check

A rollback strategy is also documented for restoring a previously working Docker image.

## 2. Architecture

```text
Developer
    |
    | git push
    v
GitHub Repository
    |
    v
GitHub Actions
    |-- npm ci
    |-- npm run lint
    |-- GitHub OIDC
    |-- Docker Build
    v
Amazon ECR
    |
    v
AWS SSM
    |
    v
Amazon EC2
    |
    v
Docker Container
    |
    v
Nginx
    |
    v
React Application
    |
    v
Health Check
```

## 3. Technologies Used

| Technology | Purpose |
|---|---|
| React | Frontend application |
| Vite | Build tool |
| Docker | Containerization |
| Nginx | Serves production React build |
| GitHub Actions | CI/CD |
| GitHub OIDC | AWS authentication |
| IAM | Access control |
| Amazon ECR | Docker image registry |
| Amazon EC2 | Application server |
| AWS SSM | Remote deployment |
| Terraform | Infrastructure as Code |
| AWS CLI | AWS management |

## 4. AWS Configuration

| Configuration | Value |
|---|---|
| AWS Region | `ap-south-1` |
| ECR Repository | `react-devops` |
| EC2 Name Tag | `react-devops-web` |
| Container Name | `react-app` |
| Host Port | `8080` |
| Container Port | `80` |

## 5. Project Structure

```text
react-aws-devops/
├── app/
│   ├── Dockerfile
│   ├── package.json
│   ├── package-lock.json
│   └── src/
├── terraform/
├── .github/
│   └── workflows/
│       └── deploy.yml
├── docs/
│   └── rollback.md
├── README.md
└── .gitignore
```

## 6. Application

The application is a React application created using Vite.

```bash
cd app
npm ci
npm run lint
npm run build
```

Current lint validation completed successfully:

```text
Found 0 warnings and 0 errors.
```

## 7. Dockerization

The React application is containerized using Docker. The build creates the production React files and serves them through Nginx.

The EC2 host maps port `8080` to container port `80`.

```text
EC2 :8080
    |
    v
Docker :80
    |
    v
Nginx
    |
    v
React
```

## 8. Terraform

Terraform configuration is maintained in:

```text
terraform/
```

Typical workflow:

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

Terraform is used to manage the required AWS infrastructure as code.

## 9. GitHub OIDC Authentication

GitHub Actions uses OpenID Connect instead of storing long-lived AWS access keys.

Workflow permissions:

```yaml
permissions:
  id-token: write
  contents: read
```

The workflow assumes the IAM role:

```text
react-devops-github-actions-role
```

Authentication flow:

```text
GitHub Actions
      |
      | OIDC
      v
AWS IAM
      |
      | Assume Role
      v
AWS Resources
```

## 10. GitHub Actions CI/CD

Workflow file:

```text
.github/workflows/deploy.yml
```

The workflow is triggered by pushes to `main`.

Pipeline:

```text
Checkout
   |
npm ci
   |
npm run lint
   |
AWS OIDC
   |
Docker Build
   |
ECR Push
   |
Find EC2
   |
SSM Deployment
   |
Health Check
```

## 11. Amazon ECR

Docker images are stored in the ECR repository:

```text
react-devops
```

Example image URI:

```text
840986437653.dkr.ecr.ap-south-1.amazonaws.com/react-devops:<image-tag>
```

Version-specific image tags allow previous application versions to be identified.

## 12. EC2 Deployment Using SSM

The running EC2 instance is identified using:

```text
Name=react-devops-web
```

AWS SSM sends deployment commands to the EC2 instance.

Deployment flow:

```text
GitHub Actions
      |
      v
SSM SendCommand
      |
      v
EC2
      |
      v
Docker Login
      |
      v
Docker Pull
      |
      v
Docker Container
```

## 13. Docker Deployment

Container name:

```text
react-app
```

Port mapping:

```text
8080:80
```

Example:

```bash
docker run -d   --name react-app   -p 8080:80   <image>
```

## 14. Health Check

The deployment verifies the application with:

```bash
curl -I http://127.0.0.1:8080
```

Expected response:

```text
HTTP/1.1 200 OK
```

Container health can be checked with:

```bash
docker inspect react-app   --format 'Image={{.Config.Image}} Status={{.State.Status}} Health={{.State.Health.Status}}'
```

Expected:

```text
Status=running
Health=healthy
```

## 15. Deployment Verification

```bash
docker ps
docker ps -a

docker inspect react-app   --format '{{.Config.Image}}'

curl -I http://127.0.0.1:8080
```

## 16. Rollback Strategy

The previous working image is tracked in:

```text
/opt/react-app/previous-image
```

Check it with:

```bash
cat /opt/react-app/previous-image
```

Rollback documentation:

```text
docs/rollback.md
```

Rollback concept:

```text
New Deployment
      |
      v
Health Check
   |       |
 PASS     FAIL
   |       |
   v       v
Success  Previous Image
             |
             v
          Rollback
```

## 17. Port Conflict Issue and Resolution

During deployment testing, the following Docker error occurred:

```text
Bind for 0.0.0.0:8080 failed:
port is already allocated
```

The container could not start because port `8080` was already allocated.

The problem was diagnosed using:

```bash
docker inspect react-app   --format 'Status={{.State.Status}} ExitCode={{.State.ExitCode}} Error={{.State.Error}}'
```

Port usage can be checked with:

```bash
sudo ss -lntp | grep :8080
```

Docker mappings can be checked with:

```bash
docker ps -a --format 'table {{.Names}}\t{{.Ports}}'
```

After cleaning up the conflicting container/state and recreating the application, verification succeeded:

```text
0.0.0.0:8080->80/tcp
```

and:

```text
HTTP/1.1 200 OK
```

Final container status:

```text
Status=running
Health=healthy
```

## 18. Useful Docker Commands

```bash
docker ps
docker ps -a
docker logs react-app
docker inspect react-app
docker rm -f react-app
docker images
```

## 19. Useful AWS Commands

### ECR images

```bash
aws ecr describe-images   --repository-name react-devops   --region ap-south-1
```

### ECR login

```bash
aws ecr get-login-password   --region ap-south-1 | docker login   --username AWS   --password-stdin   840986437653.dkr.ecr.ap-south-1.amazonaws.com
```

### SSM result

```bash
aws ssm get-command-invocation   --command-id <command-id>   --instance-id <instance-id>   --region ap-south-1
```

## 20. Troubleshooting

### SSM deployment failed

Check:

- SSM agent
- EC2 IAM permissions
- ECR authentication
- Docker status
- Container logs

### Container is not running

```bash
docker ps -a
docker inspect react-app
docker logs react-app
```

### Port 8080 conflict

```bash
sudo ss -lntp | grep :8080
docker ps -a
```

### Health check failed

```bash
docker ps
docker logs react-app
curl -I http://127.0.0.1:8080
```

## 21. Git Workflow

```bash
git status
git add .
git commit -m "update documentation"
git push origin main
```

A push to `main` triggers the GitHub Actions workflow.

## 22. End-to-End Flow

```text
Developer
    |
    | git push
    v
GitHub
    |
    v
GitHub Actions
    |
    +--> Checkout
    +--> npm ci
    +--> npm run lint
    +--> OIDC Authentication
    +--> Docker Build
    +--> ECR Push
    +--> Find EC2
    +--> SSM Deployment
    +--> Docker Pull
    +--> Docker Run
    +--> Health Check
    |
    v
Deployment Verified
```

## 23. Project Outcome

This project demonstrates practical implementation of:

- React deployment
- Docker containerization
- Nginx
- Amazon ECR
- Amazon EC2
- AWS SSM
- GitHub Actions CI/CD
- GitHub OIDC
- Terraform
- Health checks
- Versioned Docker images
- Rollback image tracking
- Docker troubleshooting
- Port conflict resolution

## 24. Repository

GitHub:

```text
https://github.com/kmsuman2705/react-aws-devops
```

## 25. Conclusion

This project demonstrates an end-to-end DevOps workflow for deploying a containerized React application on AWS.

The application is validated through GitHub Actions, packaged as a Docker image, stored in Amazon ECR and deployed to EC2 using AWS SSM.

Terraform manages infrastructure as code, while GitHub OIDC provides secure AWS authentication.

The project also covers deployment verification, troubleshooting, port conflict resolution and rollback image tracking.
