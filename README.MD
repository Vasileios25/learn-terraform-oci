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
* Strengthened understanding of **OCI VCN architecture** (VCNs, subnets, route tables, IGW, NAT Gateway, Service Gateway)
* Gained confidence deploying **Oracle Kubernetes Engine (OKE)** clusters using Terraform
* Practiced debugging common OKE failure modes:

  1. Node pools hanging during creation
  2. Missing or incorrect route tables
  3. OCI IAM policy and trust relationship issues

---

# Troubleshooting & Lessons Learned (OKE vs EKS)

While deploying an **Oracle Kubernetes Engine (OKE)** cluster with Terraform, I encountered and resolved several issues related to **compute compatibility, networking, security, authentication, and Kubernetes runtime behavior**. Many of these differ significantly from the defaults and abstractions provided by **AWS EKS**.

---

## 1. Node Pool Hanging During Creation

### Issues Encountered

* Node pool stuck in `CREATING`
* Worker nodes never transitioned to `ACTIVE`

### Root Causes

* Incompatible **node shape ↔ image ↔ Kubernetes version** combinations
* Use of non-OKE-curated images
* ARM shapes (A1 / A2 Flex) require explicit ARM-compatible images

### Resolution

* Switched to **OKE-curated images only**
* Ensured:

  * Kubernetes version matches the image
  * Image supports the selected shape (ARM vs x86)
* Used supported Flex shapes (e.g. `VM.Standard.A2.Flex`)

### Lesson Learned

OKE is far stricter than EKS about image compatibility.

EKS abstracts this away; OKE requires you to be explicit.

---

## 2. Networking Misconfigurations (VCN, Subnets, Routing)

### Issues Encountered

* Nodes created but Kubernetes API server unreachable
* `kubectl` timeouts on port `6443`
* Worker nodes had no outbound internet access

### Root Causes

* Misunderstanding OCI’s routing model
* Missing NAT Gateway routes for private subnets
* Incorrect Service Gateway configuration

### Resolution

**Public subnet**

* Route `0.0.0.0/0` → Internet Gateway

**Private subnet**

* Route `0.0.0.0/0` → NAT Gateway
* Route OCI services → Service Gateway

Used **one** OCI service CIDR only:

```
destination = "all-<region>-services-in-oracle-services-network"
```

Avoided mixing multiple OCI service CIDRs (invalid in OCI).

### Lesson Learned

OCI route tables are attached **directly to subnets**.

There are no separate route table association resources like in AWS.

---

## 3. Security Lists vs NSGs (OCI-Specific)

### Issues Encountered

* Confusion about whether Security Lists were required
* Cluster only functioned correctly after NSG rules were added

### Key Insight

Security Lists are **not obsolete**, but:

* OCI strongly recommends **NSGs** for OKE
* OKE examples and best practices assume NSGs

### Resolution

* Used **NSGs exclusively**:

  * Control plane NSG
  * Worker node NSG
* Opened:

  * TCP `6443` → control plane
  * Node-to-node and pod CIDRs
* Left Security Lists minimal / unused

### Lesson Learned

* **OCI NSGs ≈ AWS Security Groups**
* **Security Lists ≈ legacy, subnet-wide firewall rules**

---

## 4. Kubernetes API Server (Port 6443) Unreachable

### Issues Encountered

* `kubectl get nodes` timed out
* `curl https://<api-ip>:6443` hung

### Root Causes

* Missing NSG ingress rule for control plane
* Client source CIDR not explicitly allowed

### Resolution

* Added NSG ingress rule:

  * Protocol: TCP
  * Port: `6443`
  * Source: client public IP or trusted CIDR
* Verified the cluster endpoint was public

### Lesson Learned

OKE control plane access is **locked down by default**.

EKS automatically allows kubectl access for authorized IAM users.

---

## 5. Image Pull Failures (ImagePullBackOff / ImageInspectError)

### Issues Encountered

* Pods stuck in:

  * `ImagePullBackOff`
  * `ImageInspectError`

Error message:

```
short name mode is enforcing, image name nginx is ambiguous
```

### Root Cause

* Kubernetes **v1.34+** enforces fully qualified image names
* OCI uses containerd with strict short-name resolution
* EKS currently defaults to permissive behavior

### Resolution

Used fully qualified image references:

```
image: docker.io/library/nginx:1.14.2
```

Alternatively, configure image mirrors or registries explicitly.

### Lesson Learned

This is **not SELinux**.

This is containerd + Kubernetes v1.34 behavior.

OKE exposes this earlier than EKS.

---

## 6. NAT Gateway & Private Node Internet Access

### Issues Encountered

* Nodes created but unable to:

  * Pull container images
  * Reach external registries

### Root Cause

* Private subnet without a NAT Gateway route

### Resolution

* Added route:

  * `0.0.0.0/0` → NAT Gateway
* Verified outbound access from worker nodes

### Lesson Learned

OKE worker nodes do **not** get internet access by default.

EKS hides this behind opinionated VPC patterns.

---

## 7. IAM & Authentication Issues

### Issues Encountered

* kubeconfig generated but authentication failed
* Kubernetes API calls rejected

### Root Causes

* Missing or incorrect OCI IAM policies
* Incorrect assumptions based on AWS IAM behavior

### Resolution

* Verified policies for:

  * Cluster management
  * Node pools
  * User / group access
* Regenerated kubeconfig using:

```
oci ce cluster create-kubeconfig --token-version 2.0.0
```

### Lesson Learned

OCI IAM is **policy-first and explicit**.

EKS hides most permissions behind managed IAM roles.

---

## 8. Key Conceptual Differences: EKS vs OKE

| Area                    | EKS                   | OKE                   |
| ----------------------- | --------------------- | --------------------- |
| Image compatibility     | Abstracted            | Strict                |
| Routing                 | Implicit defaults     | Fully explicit        |
| Route table association | Separate resource     | Subnet property       |
| Security model          | Security Groups only  | NSGs + Security Lists |
| API access              | Automatically allowed | Must open 6443        |
| Short image names       | Allowed               | Blocked (v1.34+)      |
| NAT behavior            | Opinionated           | DIY                   |
| IAM complexity          | Hidden                | Explicit              |

---

## Final Takeaway

OKE is **lower-level and more explicit** than EKS.

You gain control and predictability, but you must understand:

* OCI networking
* Route tables
* NSGs
* Image requirements
* Kubernetes runtime changes

OKE feels closer to **“raw Kubernetes on cloud primitives”**,
while EKS feels like **“Kubernetes as a service.”**

---

# Authentication Pitfall: AWS vs OCI (Terraform)

A key issue encountered was mixing **AWS authentication assumptions** with OCI.

| Platform | Terraform supports session / OAuth auth |
| -------- | --------------------------------------- |
| AWS      | ✅ Yes (SSO, STS, AssumeRole)            |
| OCI      | ❌ No (CLI-only feature)                 |

### AWS

Terraform works seamlessly with:

* AWS SSO
* AssumeRole
* STS temporary credentials

Because:

* AWS SDKs automatically refresh credentials
* Terraform relies on the AWS SDK for authentication

### OCI

OCI provides three authentication modes:

| Auth Mode             | CLI  | Terraform             |
| --------------------- | ---  | --------------------  |
| API Key (RSA signing) | ✅   | ✅                    |
| Session / OAuth       | ✅   | ❌                    |
| Instance Principal    | ✅   | ✅ (OCI compute only) |

OCI session authentication:

* Is designed for **human CLI use**
* Uses OAuth tokens and short-lived keypairs
* Is stored under `~/.oci/sessions`
* Is **not supported** by the Terraform backend

Terraform **cannot**:

* Refresh OAuth tokens
* Read `security_token_file`
* Rotate session credentials

### Correct OCI Terraform Setup

```ini
# ~/.oci/config
[DEFAULT]
user=ocid1.user.oc1..aaaa...
tenancy=ocid1.tenancy.oc1..aaaa...
region=eu-frankfurt-1
fingerprint=aa:bb:cc:dd:ee
key_file=~/.oci/terraform_api_key.pem
```

```hcl
terraform {
  backend "oci" {
    bucket    = "bucket-state"
    key       = "state/state.tfstate"
    namespace = "frgrrigu4nsa"
    region    = "eu-frankfurt-1"
    auth      = "APIKey"
  }
}
```


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
