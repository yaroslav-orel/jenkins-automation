# Description
Provisioning of up and running Jenkins instance in minutes using `Terraform` and `Ansible`. 
Script supports customization of admin credentials, home directory, JAVA options and port as well as initial plugin installations. Setup wizard is skipped so in the end you are getting ready to roll Jenkins. 
Currently only AWS infrastructure is supported

# Terraform

## Terraform Prerequisites
- Create `ansible` SSH key in your `~/.ssh` directory
- Configure AWS CLI access to your AWS account
- Define required variables by creating `terraform.tfvars` file inside `terraform/` directory

### Required variables: 
- `vpc_id` (VPC in which EC2 should be provisioned)
- `subnet` (Subnet ID in which EC2 should be provisioned)
- `client_cidr` (IP that should be whitelisted to access SSH and UI)
- `os_type` (Underlying OS of the EC2. 2 options are available: `amazon` and `ubuntu`)


## Provision AWS infra 
```
cd terraform
terraform init
terraform apply --auto-approve
```

# Ansible

## Install Jenkins on EC2

### NOTE: It is recommended to change default password before starting installation by modifying `jenkins_admin_password` in `ansible/roles/jenkins/vars/variables.yml`

```
cd ansible
ansible-playbook main.yml
```
