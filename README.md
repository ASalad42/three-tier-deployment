
# Three Tier Architecture Deployment and Monitoring

- Data Layer (Database)
  - db.js handles database connection using Mongoose.
- Application Layer (Backend)
  - index.js sets up a basic Express.js server, connects to the database, exposes routes for creating, updating, deleting and reading tasks and handles http requests.
- Presentation (Frontend)
  - app.js -  React app that displays tasks, allows users to create, delete, and update tasks. App.js component renders the task list, input forms, and buttons, which interact with the backend.
![image](https://github.com/user-attachments/assets/46ca3d9d-3a3e-449d-85ea-4fc3025c912f)

Jenkins setup:

- setup application code
- write out terraform IaC - use this to setup aws infastrcuture which will host application code
- prepare k8 manifest files to deploy backend and frontend
- aws configure
- create dynamodb table for lock files with PK LockID and s3 bucket manually
- terraform init
- terraform validate
- ![image](https://github.com/user-attachments/assets/f0a8b0c5-e366-460f-ae6a-e0504057e1bb)

- terraform plan -var-file="variables.tfvars"
- ![image](https://github.com/user-attachments/assets/525059fc-b610-4e78-b004-a02effbe06e2)

- create key pair devtf manually
- terraform apply -var-file="variables.tfvars" --auto-approve
- ![image](https://github.com/user-attachments/assets/df21f5c8-72f2-4049-af6c-4e794954e353)

- terraform destroy -var-file="variables.tfvars"
- ![image](https://github.com/user-attachments/assets/71c91a1b-ba5c-415e-b789-217e335721ef)

- connect to jenkins server

```
Host jenkins-server
    HostName 3.252.191.8
    User ubuntu
    IdentityFile ~/.ssh/devtf.pem

```

- validate user data (tools-install.sh) for ec2 worked by checking if tools are installed on the server.
- Check the user_data log with command `cat /tmp/user_data.log`
- This will output the log of the commands executed during the user data processing. scroll through it to check if any errors occurred during the execution of script.
- jenkins --version, docker --version, docker ps, terraform --version, kubectl version, aws --version, trivy --version, eksctl --version
- ![image](https://github.com/user-attachments/assets/c750e374-2545-4d03-88cd-cf7557292996)

- Access jenkins server on browser using public ip 3.252.191.8:8080
- sudo cat /var/lib/jenkins/secrets/initialAdminPassword
- ![image](https://github.com/user-attachments/assets/e15c8c54-d9d9-40d2-924b-04e2a89f1196)

- ![image](https://github.com/user-attachments/assets/7cea7562-e857-488f-bd0c-6724c5a4375b)


EKS Set up

- manage plugins > Available plugins > AWS Credentials and Pipeline: AWS Steps. Restart.
- manage plugins > credentials > global > AWS Access Key & Secret Access key + github token
- aws configure
- eksctl create cluster --name Three-Tier-Cluster --region eu-west-1 --node-type t2.medium --nodes-min 2 --nodes-max 2
- ![image](https://github.com/user-attachments/assets/1576b2f4-951e-43fa-9a0d-7168f8aa089b)

- ![image](https://github.com/user-attachments/assets/1bbbede3-d9ab-404c-9d5c-329619e3972a)

- ![image](https://github.com/user-attachments/assets/9a259193-4514-4c35-90b4-e41721bc5d69)

- aws eks update-kubeconfig --region eu-west-1 --name Three-Tier-Cluster
- kubectl get nodes
- ![image](https://github.com/user-attachments/assets/65fcc76e-69f4-47a2-9daf-e676554fa62f)

- curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.5.4/docs/install/iam_policy.json
- aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://iam_policy.json
- OIDC Provider
  - eksctl utils associate-iam-oidc-provider --region=eu-west-1 --cluster=Three-Tier-Cluster --approve
  - aws eks describe-cluster --name Three-Tier-Cluster --region eu-west-1 --query "cluster.identity.oidc.issuer" --output text
- Service Account
  - delete stack eksctl-Three-Tier-Cluster-addon-iamserviceaccount-kube-system-aws-load-balancer-controller  which failed because role already existed 
  - eksctl create iamserviceaccount --cluster=Three-Tier-Cluster --namespace=kube-system --name=aws-load-balancer-controller --role-name AmazonEKSLoadBalancerControllerRoleNew --attach-policy-arn=arn:aws:iam::207204475805:policy/AWSLoadBalancerControllerIAMPolicy --approve --region=eu-west-1
- ![image](https://github.com/user-attachments/assets/c15d741b-2910-4497-b672-1b8ce5939804)

- AWS Load Balancer Controller
- sudo snap install helm --classic
- helm repo add eks https://aws.github.io/eks-charts
- helm repo update eks
- helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --set clusterName=Three-Tier-Cluster --set serviceAccount.create=false --set serviceAccount.name=aws-load-balancer-controller
- kubectl get deployment -n kube-system aws-load-balancer-controller
- ![image](https://github.com/user-attachments/assets/71bc068f-82f2-4948-8430-379558879487)


ECR Repositories :

- create 2 repositories, one for backend and the other for frontend.
- aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin 207204475805.dkr.ecr.eu-west-1.amazonaws.com
- .docker/config.json file created
- ![image](https://github.com/user-attachments/assets/b4153a3c-0045-4812-8dc0-5bcb31cacde5)


ArgoCD:

- kubectl create namespace three-tier

```
kubectl create secret generic ecr-registry-secret \
  --from-file=.dockerconfigjson=${HOME}/.docker/config.json \
  --type=kubernetes.io/dockerconfigjson --namespace three-tier
```

- kubectl get secrets -n three-tier
- ![image](https://github.com/user-attachments/assets/a99c8f28-816b-4420-9d3e-d97402b0be5e)

- kubectl create namespace argocd
- kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.4.7/manifests/install.yaml
- kubectl get pods -n argocd
- kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
- ![image](https://github.com/user-attachments/assets/20fe6300-675b-4dbd-80ac-ae3b3e759814)

- ![image](https://github.com/user-attachments/assets/15d36a48-8b2a-48be-b7ce-627565a88b80)

- sudo apt install jq -y
- export ARGOCD_SERVER='kubectl get svc argocd-server -n argocd -o json | jq - raw-output '.status.loadBalancer.ingress[0].hostname''
- export ARGO_PWD='kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d'
- echo $ARGO_PWD
- nGbF1Ul1is1fffHf


Sonarqube:

- access on http://3.252.191.8:9000
- username and password admin 
- token squ_377b6883a0353dbe871fccccc02111a29517d77d
- create webhook for jenkins  http://3.252.191.8:8080/sonarqube-webhook/

- frontend > use the below in Jenkins Frontend Pipeline
```
sonar-scanner \
  -Dsonar.projectKey=three-tier-architecture-frontend \
  -Dsonar.sources=. \
  -Dsonar.host.url=http://3.252.191.8:9000 \
  -Dsonar.login=squ_377b6883a0353dbe871fccccc02111a29517d77d
```
- backend > use the below in Jenkins Backend Pipeline
```
sonar-scanner \
  -Dsonar.projectKey=three-tier-architecture-backend \
  -Dsonar.sources=. \
  -Dsonar.host.url=http://3.252.191.8:9000 \
  -Dsonar.login=squ_377b6883a0353dbe871fccccc02111a29517d77d
```

- ![image](https://github.com/user-attachments/assets/3fff43f1-22ef-4146-8e45-68ab5d584187)
- Install plugins: Docker, Docker Commons, Docker Pipeline, Docker API, docker-build-step, Eclipse Temurin installer, NodeJS, OWASP Dependency-Check, SonarQube Scanner
- Dashboard -> Manage Jenkins -> Tools > provide configuration for tools
- Dashboard -> Manage Jenkins -> System > SonarQube installations
- ![image](https://github.com/user-attachments/assets/b68a28d6-4de2-482a-9ef8-fcc6a25f9aa5)

Jenkins Pipeline to deploy our Backend Code:

- dashboard > new item > pipeline > copy pipeline code into jenkins pipeline
- use access token instead of password along with the username. 
- create policy for ecr push and attach to jenkins role
- ![image](https://github.com/user-attachments/assets/5de29436-c7a9-4501-984d-cbd4e0902040)
- ![image](https://github.com/user-attachments/assets/13616f2f-a50e-4ca8-a156-dbcf0890a09f)
- ![image](https://github.com/user-attachments/assets/bd596132-955c-4fb2-8e2b-317c4dcd2772)







Monitoring with Prometheus & Grafana:

- helm repo add stable https://charts.helm.sh/stable
- helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
- helm install prometheus prometheus-community/prometheus
- helm repo add grafana https://grafana.github.io/helm-charts
- helm repo update
- helm install grafana grafana/grafana
- kubectl get svc
- kubectl edit svc prometheus-server
- helm upgrade prometheus prometheus-community/prometheus --set server.service.type=LoadBalancer --set alertmanager.service.type=LoadBalancer
- change ClusterType to LoadBalancer
- kubectl edit svc grafana
- helm upgrade grafana grafana/grafana --set service.type=LoadBalancer
- change ClusterType to LoadBalancer
- kubectl get svc
- ![image](https://github.com/user-attachments/assets/8221b1d9-cbbf-46fb-854b-9f56e41badd2)
- Access prometheus on <Prometheus-LB-DNS>:80
- ensure ebs-csi for pvc and pv. or create manually.
- fix finalizer for PVC: kubectl patch pvc storage-prometheus-alertmanager-0 -n default -p '{"metadata":{"finalizers":null}}' --type=merge
- kubectl delete pvc storage-prometheus-alertmanager-0 -n default
- Access grafana on Grafana-LB-DNS:80 > setup connection > use HTTP://Prometheus-LB-DNS:80
- ![image](https://github.com/user-attachments/assets/5c380fff-b0a9-40b3-b467-d081735a04df)
- ![image](https://github.com/user-attachments/assets/3bcbd00f-d3bc-42f5-9cf1-6567652fbd2f)
- ![image](https://github.com/user-attachments/assets/b277d5bd-7eee-4e84-8f82-14d9dd138cee)
- import k8 dashboard
- ![image](https://github.com/user-attachments/assets/75ddde19-50e9-46cb-a658-bc8a0f149fe2)
- ![image](https://github.com/user-attachments/assets/3e3d36c6-94bf-4d25-bc64-db890eba8a8b)



Deploy using ArgoCD:

- Repos > CONNECT REPO USING HTTPS > use username and token again as password is no longer allowed
- connection successful
- ![image](https://github.com/user-attachments/assets/f7d04fb8-c001-41bb-afaf-400b697cb82c)
- In EKS PV and PVC set up for db deployment. So, if pods get deleted then, data won’t be lost. delete both db pods and notice when new ones start up that no data was lost.
- ![image](https://github.com/user-attachments/assets/72b00e76-13ef-4cf0-b756-533d63a9f7f8)
- ![image](https://github.com/user-attachments/assets/84e28dd5-a1b6-478b-b6c3-e86bae8aab37)
- ![image](https://github.com/user-attachments/assets/a8fb249d-12a4-44aa-a6a5-d6469d2a0a7c)
- argoCD monitors the manifest files in db, frontend and backend and if any changes in the code then delpoys configuration.



