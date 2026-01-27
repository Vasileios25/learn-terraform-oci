#  OCI OKE Cluster with Terraform (Work in Progress)

##  Overview
This project provisions a fully functional OCI OKE cluster using Terraform, following real-world DevOps and cloud infrastructure practices:
1. **Custom VCN**
2. **One public subnet and one private subnet** 
3. **Internet Gateway**, **Route Tables**, **Service Gateway** and **NAT Gateway**
4. **OCI OKE Control Plane**
5. **Managed OKE Node Group (worker nodes)**
6. **IAM roles & policy attachments**
7. **kubectl access** to the cluster


The goal is to create a clean, production-style environment that will later be extended with private networking, add-ons, CI/CD, and application deployments.

---

##  Current Status
 Working components:
- VCN created with /16 CIDR
- 2  subnets created with 10.0.1.0/24 for public(OKE Control Plane endpoint, Internet Gateway attached) and 10.0.2.0/24 for private(Worker nodes (no public IPs), NAT Gateway for outbound internet access)
- Service Gateway: Access to OCI services without traversing the internet
- Internet Gateway + public route table (0.0.0.0/0)
- OCI OKE cluster successfully deployed
- Managed NodeGroup running in public subnets
- OCI IAM policies configured for worker nodes (CNI, Worker Node access, OCIR pull)

 In progress:
- Refactoring  into Terraform modules
- Deploying a sample microservice to OKE
- Implementing CI/CD pipeline 
- Adding  add-ons (ALB Controller, Autoscaler, Metrics Server)
- Right now, I’m running OKE with public API access because it simplifies cluster management from my laptop. In production, I can fully private the API endpoint.
I understand how private clusters work, but I chose a public API endpoint during learning to avoid unnecessary complexity
- Set up Ingress with TLS 

---

##  What I’ve Learned So Far
- Strengthened understanding of **OCI VCN architecture(subnets, route tables, IGW, CIDR math with cidrsubnet)**
- Gained confidence deploying **OKE clusters** programmatically 
- Practiced debugging common OKE issues like:
    1)NodeGroup hanging on creation
    2)Missing route tables
    3)IAM trust relationships

---

##  Next Steps
1. Autoscaling node pools 
2. Private API endpoint
3. Multiple availability domains 
4. OCI Load Balancer integration 
5. Terraform modules & CI/CD pipeline

---

##  Project Context
This is a **personal learning project**, not production-ready code.  
Its purpose is to document my growth as a Cloud / DevOps engineer — from manual operations to automated, secure infrastructure design.

I started this to connect my interests in:
- **OCI DevOps**
- **Networking**
- **Automation**

---

My aim is to demonstrate:
- Curiosity and willingness to explore complex topics  
- Practical, hands-on problem solving  
- Continuous improvement mindset  

---

## Tech Stack
| Component          | Purpose                                   |
| ------------------ | ----------------------------------------- |
| **Terraform**      | Infrastructure as Code                    |
| **OCI OKE**        | Kubernetes control plane                  |
| **EC2 Node Group** | Worker nodes running pods(A2 Flex)        |
| **OCI IAM**        | Role & policy management                  |
| **OCI Storage**    | Terraform Remote State                    |
| **kubectl**        | Kubernetes interaction                    |
| *(Future)*         | Helm, Prometheus, Grafana, GitHub Actions |
    



## Getting Started

### Prerequisites
- Configured OCI credentials (API signing key)  
- Terraform v1.7+
- kubectl
- AWS CLI v2
- Sufficient OCI IAM permissions to create networking and OKE resources

### Clone
```bash
git clone https://your-repo-url.git
cd OCI-VCN

   ```



### Executing program

Connect to the Cluster:
```bash
oci ce cluster create-kubeconfig \
--cluster-id <cluster_ocid> \
--file $HOME/.kube/config \
--region eu-frankfurt-1 \
--token-version 2.0.0 \
--kube-endpoint PUBLIC_ENDPOINT



```


##  Author
**Vasileios Siaploulis**  
Cloud / DevOps Engineer in progress 
Passionate about Linux, networking, and secure automation.  



---
