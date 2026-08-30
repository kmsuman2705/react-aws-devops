# React AWS DevOps Project

## 1. Project Overview

This project demonstrates a production-style CI/CD deployment of a React application on AWS using Docker, Amazon ECR, Amazon EC2, AWS Systems Manager (SSM), GitHub Actions, GitHub OIDC and Terraform.

The deployment pipeline automatically:

1. Checks out the source code
2. Installs application dependencies
3. Runs lint checks
4. Authenticates with AWS using GitHub OIDC
5. Finds the running EC2 instance
6. Builds the Docker image
7. Pushes the Docker image to Amazon ECR
8. Deploys the application to EC2 using AWS SSM
9. Performs an application health check
10. Keeps the previous Docker image available for rollback
11. Rolls back to the previous image if the deployment fails


---

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
    |
    +--> npm ci
    |
    +--> npm run lint
    |
    +--> Configure AWS using OIDC
    |
    +--> Find EC2
    |
    +--> Docker Build
    |
    v
Amazon ECR
    |
    | Docker Image
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
    |
    +---- SUCCESS ----> Deployment Successful
    |
    +---- FAILURE ---> Rollback
                           |
                           v
                    Previous Image
                           |
                           v
                    Health Check
                           |
                           v
                    Application Restored


  3. Deployment Flow

  Developer
    |
    | git push
    v
GitHub
    |
    v
GitHub Actions
    |
    +--> Checkout Code
    |
    +--> npm ci
    |
    +--> npm run lint
    |
    +--> AWS OIDC Authentication
    |
    +--> Find Running EC2
    |
    +--> Login to ECR
    |
    +--> Build Docker Image
    |
    +--> Push Image to ECR
    |
    +--> Deploy using SSM
    |
    +--> Health Check
    |
    +--> Success / Rollback


4. AWS Services Used

| Service        | Purpose                        |
| -------------- | ------------------------------ |
| GitHub Actions | CI/CD automation               |
| GitHub OIDC    | Secure authentication with AWS |
| IAM            | Access control                 |
| Amazon ECR     | Docker image registry          |
| Amazon EC2     | Application server             |
| AWS SSM        | Remote command execution       |
| Terraform      | Infrastructure provisioning    |
| Docker         | Application containerization   |
| Nginx          | Serving React production files |


5. Project Structure


react-aws-devops/
│
├── app/
│   ├── Dockerfile
│   ├── package.json
│   ├── package-lock.json
│   ├── src/
│   └── nginx/
│       └── nginx.conf
│
├── terraform/
│   └── Terraform configuration files
│
├── .github/
│   └── workflows/
│       └── deploy.yml
│
├── docs/
│   └── rollback.md
│
├── README.md
├── .gitignore
└── terraform.tfstate

6. Application Configuration

AWS Region       : ap-south-1
ECR Repository   : react-devops
EC2 Name Tag     : react-devops-web
Container Name   : react-app
Host Port        : 8080
Container Port   : 80

ECR Registry:

840986437653.dkr.ecr.ap-south-1.amazonaws.com
ECR Repository:
react-devops
7. React Application
The application is a React application built using Vite.
Main application files include:
package.json
package-lock.json
src/
The production build is generated using:
npm run build
The generated production files are stored in:
dist/
8. Application Testing
Before creating the Docker image, the application dependencies are installed and linting is performed.
cd app
npm ci
npm run lint
Expected result:
Found 0 warnings and 0 errors.
This ensures that the application passes the code quality check before the Docker image is built.
9. Dockerization
The React application is containerized using Docker.
The Dockerfile uses a multi-stage build.
Node.js Build Stage
        |
        v
npm ci
        |
        v
Copy Application Source
        |
        v
npm run build
        |
        v
dist/
        |
        v
Nginx Runtime Stage
        |
        v
React Production Application
Nginx is used as the production web server to serve the React static files.
10. Docker Image Build
The image is tagged for Amazon ECR:
docker tag \
  react-devops:latest \
  840986437653.dkr.ecr.ap-south-1.amazonaws.com/react-devops:latest
  For deployment tracking, commit SHA based image tags are also used.
  Example:
  react-devops:2b5d035fc6a6b82c471ed1f7f4b4f4bcc85bc73e
  11. GitHub Actions CI/CD
  Workflow file:
  .github/workflows/deploy.yml
  The workflow is triggered when code is pushed to the main branch.
  on:
  push:
    branches:
      - main


      The pipeline performs the following steps:
      Checkout
   |
   v
Install Dependencies
   |
   v
Lint
   |
   v
AWS Authentication
   |
   v
EC2 Discovery
   |
   v
ECR Login
   |
   v
Docker Build
   |
   v
Docker Push
   |
   v
SSM Deployment
   |
   v
Health Check
   |
   v
Success / Rollback

12. GitHub OIDC Authentication
GitHub Actions authenticates with AWS using OpenID Connect.
The workflow uses:
permissions:
  id-token: write
  contents: read
  AWS IAM Role:
  react-devops-github-actions-role
  GitHub Actions assumes this IAM role to access the required AWS resources.
  This avoids storing long-lived AWS access keys in GitHub.
  13. EC2 Discovery
  The deployment dynamically finds the running EC2 instance instead of hard-coding the instance ID.
  The EC2 instance is identified using the Name tag:
  Name=react-devops-web
  The workflow searches only for running instances.
  The instance ID is stored in:
  EC2_INSTANCE_ID
  This allows the deployment workflow to locate the current application server automatically.
  14. Amazon ECR
  Amazon ECR is used as the private Docker image registry.
  Repository:
  react-devops
  Region:
  ap-south-1
  Deployment flow:
  Docker Build
     |
     v
Docker Tag
     |
     v
ECR Login
     |
     v
Docker Push
Example image:
840986437653.dkr.ecr.ap-south-1.amazonaws.com/react-devops:<commit-sha>
15. AWS SSM Deployment
AWS Systems Manager is used to execute deployment commands on the EC2 instance.
GitHub Actions sends commands using:
AWS-RunShellScript
Deployment flow:
GitHub Actions
      |
      v
SSM SendCommand
      |
      v
EC2 Instance
      |
      v
AWS-RunShellScript
      |
      v
Docker Commands
Using SSM avoids requiring SSH private keys inside GitHub Actions.
16. Previous Image Backup
Before replacing the application container, the currently running Docker image is identified.
Command:
docker inspect react-app \
  --format '{{.Config.Image}}'
  The previous image reference is stored in:
  /opt/react-app/previous-image
  Example:

840986437653.dkr.ecr.ap-south-1.amazonaws.com/react-devops:2b5d035fc6a6b82c471ed1f7f4b4f4bcc85bc73e

This image reference is used during rollback if the new deployment fails.

17. Container Deployment

The new Docker container is started using:

docker run -d \
  --name react-app \
  -p 8080:80 \
  <IMAGE_URI>

Port mapping:

EC2 Host Port 8080
        |
        v
Docker Container Port 80
        |
        v
Nginx
        |
        v
React Application
18. Container Replacement

During deployment, the existing container is removed and recreated with the new image.

The container is removed using:

docker rm -f react-app

Important:

The old container is removed.

The old Docker image is not deleted.

The previous image remains available for rollback.

Flow:

Running Container
       |
       v
Save Previous Image
       |
       v
Remove Old Container
       |
       v
Pull New Image
       |
       v
Start New Container
       |
       v
Health Check
19. Port Conflict Handling

During implementation, a real port conflict was encountered.

The error was:

Bind for 0.0.0.0:8080 failed:
port is already allocated

The port was investigated using:

sudo ss -lntp | grep :8080

Docker containers were checked using:

docker ps -a --filter "publish=8080"

The container state was checked using:

docker inspect react-app \
  --format 'Status={{.State.Status}} ExitCode={{.State.ExitCode}} Error={{.State.Error}}'

After resolving the conflict, the application container was started successfully.

Final verification:

docker ps

and:

curl -I http://127.0.0.1:8080

Expected:

HTTP/1.1 200 OK
20. Application Health Check

After deploying the container, the application is checked using:

curl -I http://127.0.0.1:8080

Expected response:

HTTP/1.1 200 OK

The deployment script also captures the HTTP status code.

HTTP_CODE=$(curl -s \
  -o /dev/null \
  -w "%{http_code}" \
  http://127.0.0.1:8080)

Expected result:

200

If the status code is not 200, the deployment is considered failed.

21. Docker Health Check

The container health status can be verified using:

docker inspect react-app \
  --format 'Image={{.Config.Image}} Status={{.State.Status}} Health={{.State.Health.Status}}'

Expected:

Status=running
Health=healthy

Example:

Image=840986437653.dkr.ecr.ap-south-1.amazonaws.com/react-devops:<commit-sha>
Status=running
Health=healthy
22. Automatic Rollback

If the newly deployed application fails the health check, the previous working image is restored.

Rollback flow:

New Deployment
      |
      v
Health Check
      |
      +---------- PASS ----------> Deployment Successful
      |
      |
     FAIL
      |
      v
Read Previous Image
      |
      v
Pull Previous Image
      |
      v
Remove Failed Container
      |
      v
Start Previous Container
      |
      v
Health Check
      |
      v
Previous Version Restored

The previous image is read from:

PREVIOUS_IMAGE=$(cat /opt/react-app/previous-image)

The image is pulled:

docker pull "$PREVIOUS_IMAGE"

The previous container is recreated:

docker run -d \
  --name react-app \
  -p 8080:80 \
  "$PREVIOUS_IMAGE"
23. Rollback Verification

After rollback, the application is checked again.

curl -I http://127.0.0.1:8080

Expected:

HTTP/1.1 200 OK

Container health can also be checked:

docker inspect react-app \
  --format 'Image={{.Config.Image}} Status={{.State.Status}} Health={{.State.Health.Status}}'

Expected:

Status=running
Health=healthy

This confirms that the previous working version has been restored.

24. SSM Command Verification

After sending the deployment command, GitHub Actions waits for the SSM command to complete.

The command can be checked using:

aws ssm get-command-invocation \
  --command-id <COMMAND_ID> \
  --instance-id <INSTANCE_ID> \
  --region ap-south-1

Successful status:

Success

If the status is:

Failed

the deployment pipeline fails.

25. Troubleshooting
25.1 Port Conflict

Error:

Bind for 0.0.0.0:8080 failed:
port is already allocated

Commands used for diagnosis:

sudo ss -lntp | grep :8080
docker ps -a --filter "publish=8080"
docker ps -a

After resolving the conflict, the container was started successfully.

25.2 SSM Shell Syntax Issue

During implementation, an SSM deployment command failed because of shell quoting and variable interpretation.

The error was:

Syntax error: "(" unexpected

The command construction was corrected so that shell variables were interpreted correctly on the EC2 instance.

25.3 Container Created but Not Running

A container can exist in the Created state without successfully starting.

The status can be checked using:

docker inspect react-app \
  --format 'Status={{.State.Status}} ExitCode={{.State.ExitCode}} Error={{.State.Error}}'

This helped identify the port allocation issue during deployment.

26. Manual Verification Commands
Check Running Container
docker ps
Check All Containers
docker ps -a
Check Current Image
docker inspect react-app \
  --format '{{.Config.Image}}'
Check Container Status
docker inspect react-app \
  --format 'Status={{.State.Status}} ExitCode={{.State.ExitCode}} Error={{.State.Error}}'
Check Health
docker inspect react-app \
  --format 'Status={{.State.Status}} Health={{.State.Health.Status}}'
Check Application
curl -I http://127.0.0.1:8080
Check Port
sudo ss -lntp | grep :8080
Check Docker Port Mapping
docker ps --format "table {{.Names}}\t{{.Ports}}"
27. Final Verification

The final deployment was verified using:

docker ps

Expected:

react-app
Up
healthy

The deployed image was verified using:

docker inspect react-app \
  --format '{{.Config.Image}}'

The application was verified using:

curl -I http://127.0.0.1:8080

Expected:

HTTP/1.1 200 OK

Final state:

Docker Container : Running
Health           : Healthy
Application      : HTTP 200
Host Port        : 8080
Container Port   : 80
Web Server       : Nginx
28. Deployment Failure Handling

The deployment follows this logic:

Build
  |
  v
Test
  |
  v
Push Image
  |
  v
Deploy
  |
  v
Health Check
  |
  +---- 200 OK ------> SUCCESS
  |
  +---- NOT 200 -----> ROLLBACK
                         |
                         v
                   Previous Image
                         |
                         v
                   Start Container
                         |
                         v
                   Health Check
                         |
                         v
                      RESTORED
29. Image Versioning

Commit SHA based Docker image tags are used to identify individual deployments.

Example:

react-devops:2b5d035fc6a6b82c471ed1f7f4b4f4bcc85bc73e

Advantages:

Each deployment has a unique identifier.
Previous versions can be identified.
Rollback is easier.
Multiple application versions can exist in ECR.
Deployment history can be traced back to a Git commit.
30. Rollback Strategy

The rollback strategy stores the image reference of the currently deployed application.

Current Container
       |
       v
Current Image
       |
       v
/opt/react-app/previous-image

If the new deployment fails:

previous-image
      |
      v
docker pull
      |
      v
docker run
      |
      v
Health Check
      |
      v
Previous Version Restored
31. Production Improvements

For a larger production environment, the following improvements can be added:

Blue/Green deployment
Canary deployment
Application Load Balancer
Auto Scaling Group
ECS or EKS
CloudWatch monitoring
Centralized logging
AWS Secrets Manager
AWS Systems Manager Parameter Store
ECR image vulnerability scanning
ECR lifecycle policies
Automated integration testing
Deployment approval gates
Multiple EC2 instances
Zero-downtime deployment
32. Task 2 Checklist
 React application
 Dockerization
 Docker image build
 GitHub Actions
 GitHub OIDC
 AWS IAM
 Amazon ECR
 Amazon EC2
 AWS SSM
 Dynamic EC2 discovery
 Previous image backup
 Container replacement
 Port conflict troubleshooting
 Application health check
 Docker health verification
 Automatic rollback
 Rollback verification
 SSM deployment verification
 Troubleshooting documentation
 Final verification
 README documentation
