# Terraform Basics

Terraform is an open-source infrastructure as code tool. I am using it with AWS.

## Installation

Make sure Terraform is installed and you have your Access and Secret keys set as env variables.
To download necessary AWS packages:

```bash
terraform init
```

To run the file and build a VPC, Subnet, Internet Gateway, Elastic IP, Network Interface, Route Table, Security Group, and EC2 instance:

```bash
terraform apply
```

To destroy all previously built instances:

```bash
terraform destroy
```
