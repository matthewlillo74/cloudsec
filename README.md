# Cloud Security Platform

A serverless web application that performs **cloud security scans** and allows users to **remediate misconfigurations** directly from the UI. Built with **AWS Lambda**, **API Gateway**, **S3 Static Website Hosting**, and **Terraform** for full Infrastructure-as-Code deployment.

---

## ✅ Features
- **Security Scans**: Trigger automated security checks for AWS resources.
- **Remediation Actions**: Fix misconfigurations directly from the frontend.
- **Serverless Architecture**: No servers to manage, highly scalable.
- **Infrastructure as Code**: Entire environment is deployed using Terraform.
- **Static Web Frontend**: Simple UI hosted on S3.

---

## 🏗 Architecture Overview

[ User Browser ]
|
v
[ S3 Static Website (HTML, CSS, JS) ]
|
v
[ API Gateway ] ---> [ AWS Lambda (Python) ] ---> [ DynamoDB (Scan Results) ]
|
v
[ AWS IAM Roles for Security ]


**AWS Services Used:**
- **S3** for hosting the frontend.
- **API Gateway** for exposing the API endpoints.
- **Lambda (Python)** for scan and remediation logic.
- **DynamoDB** for storing scan results.
- **IAM** for permissions.
- **CloudWatch** for logging.

---

## 🛠 Tech Stack
- **Frontend**: HTML, CSS, JavaScript
- **Backend**: Python (AWS Lambda)
- **Infrastructure**: Terraform
- **Cloud Provider**: AWS (S3, Lambda, API Gateway, DynamoDB)



