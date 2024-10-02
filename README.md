
# Three Tier Architecture deployment and monitoring

- setup application code
- write out terraform IaC - use this to setup aws infastrcuture which will host application code
- prepare k8 manifest files to deploy backend and frontend
- aws configure
- create dynamodb table for lock files with PK LockID and s3 bucket manually
- terraform init
- terraform validate
- ![alt text](image.png)
- terraform plan -var-file="variables.tfvars"
- ![alt text](image-1.png)
- create key pair devtf manually
- terraform apply -var-file="variables.tfvars" --auto-approve
- ![alt text](image-3.png)
- terraform destroy -var-file="variables.tfvars"
- ![alt text](image-2.png)
- connect to jenkins server

```
Host jenkins-server
    HostName 54.155.64.26
    User ubuntu
    IdentityFile ~/.ssh/devtf.pem

```

- validate user data (tools-install.sh) for ec2 worked by checking if tools are installed on the server.
- jenkins --version
- docker --version
- docker ps
- terraform --version
- kubectl version
- aws --version
- trivy --version
- eksctl --version
- Access jenkins server on browser using public ip 3.250.5.213:8080
