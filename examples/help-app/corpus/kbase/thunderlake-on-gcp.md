---
source: kbase
url: https://kbase.zetaris.com/knowledge/thunderlake-on-gcp
title: "Deploying Thunderlake ( GCP version)"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: 72896df6e0d64e7ad59a2ae4f0c84a8175564abc51e81ca0a4efa8ba01d48db6
---
# Deploying Thunderlake ( GCP version)

## This guide provides step-by-step instructions to deploy and run the Zetaris Lightning Catalog (Open Source) on a GPU-enabled Virtual Machine (VM) in Google Cloud Platform (GCP).

The guide covers the complete process — from provisioning the VM with the right hardware, GPU drivers, and RAPIDS support, to installing the required software stack (Conda, CUDA, NVIDIA Driver, Git, Docker), and finally launching the Lightning Catalog application via Docker Compose.

By following this guide, you will:

-   Set up a **GCP VM** with **NVIDIA V100 GPU** and optimal specs for Spark + RAPIDS workloads.
    
-   Install all necessary dependencies for GPU-accelerated Spark execution.
    
-   Pull and run the **Zetaris Lightning Catalog** in a containerized environment.
    
-   Access the web-based UI for managing and querying enterprise data assets.
    

This document assumes you already have a GCP account with permission to create VM instances and access to pull public Docker images.

#### GCP VM Prerequisites

[](https://github.com/rajaram-ramesh/Thunderlake/tree/patch-1#gcp-vm-prerequisites)

| Component | Recommended Configuration |
| --- | --- |
| 
**GPU Type**

 | NVIDIA V100 (16GB) — Best RAPIDS compatibility and proven Spark + cuDF support |
| **Machine Type** | Minimum: `n1-standard-8` (8 vCPUs, 30 GB RAM)  
Recommended: Higher for larger workloads |
| **OS** | Ubuntu 22.04 LTS |
| **Disk** | Boot Disk: 100 GB SSD |

Environment Setup

Once the VM is provisioned, install **Conda**, **RAPIDS**, **CUDA**, and the **NVIDIA Driver**.

**A. Install Conda, RAPIDS, and CUDA**

[](https://github.com/rajaram-ramesh/Thunderlake/tree/patch-1#a-install-conda-rapids-and-cuda)

Download and install Miniconda

[](https://github.com/rajaram-ramesh/Thunderlake/tree/patch-1#download-and-install-miniconda)

```
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.shbash Miniconda3-latest-Linux-x86_64.sh
```

Add Conda to PATH

```
echo 'export PATH="$HOME/miniconda3/bin:$PATH"' >> ~/.bashrcsource ~/.bashrc
```

 Create RAPIDS environment

```
conda create -n rapids-24.02 -c rapidsai -c nvidia -c conda-forge     rapids=24.02 python=3.10 cudatoolkit=11.8conda activate rapids-24.02
```

 Verify Conda installation

```
conda --version
```

**B.Install NVidia Driver**

```
sudo apt updatesudo apt install -y nvidia-driver-535sudo reboot
```

 Verify GPU access:

```
nvidia-smi
```

 **C.** **Validation:**

-   \`conda --version\` → Conda installed and accessible
-   \`nvidia-smi\` → GPU recognized and driver working

### Run Lightning Catalog on GPU VM

[](https://github.com/rajaram-ramesh/Thunderlake/tree/patch-1#run-lightning-catalog-on-gpu-vm)

Your VM should now have:

-   Ubuntu 22.04 LTS
-   NVIDIA Driver, CUDA, and RAPIDS installed

We will now:

1.  Install **Git** + **Docker**
2.  Clone the Lightning Catalog repo
3.  Run it via Docker Compose

* * *

#### **1\. Install Git, Docker, and Docker Compose**

[](https://github.com/rajaram-ramesh/Thunderlake/tree/patch-1#1-install-git-docker-and-docker-compose)

```
# Update system packagessudo apt update && sudo apt -y upgrade# Install Git & dependenciessudo apt install -y git ca-certificates curl gnupg lsb-release# Add Docker’s GPG key & reposudo install -m 0755 -d /etc/apt/keyringscurl -fsSL https://download.docker.com/linux/ubuntu/gpg |   sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpgecho   "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg]   https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" |   sudo tee /etc/apt/sources.list.d/docker.list > /dev/null# Install Docker Engine and Compose pluginsudo apt updatesudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin# (Optional) Run Docker without sudosudo usermod -aG docker $USERnewgrp docker# Verify installationdocker --versiondocker compose version
```

* * *

#### **2\. Clone the Repository**

[](https://github.com/rajaram-ramesh/Thunderlake/tree/patch-1#2-clone-the-repository)

git clone [https://github.com/zetaris/Thunderlake.git](https://github.com/zetaris/Thunderlake.git) cd Thunderlake

* * *

#### **3\. Pull the Docker Image**

[](https://github.com/rajaram-ramesh/Thunderlake/tree/patch-1#3-pull-the-docker-image)

```
# Using Compose v2docker compose pull# Legacydocker-compose pull# Specific image example:docker pull zetaris/lightning-catalog-nvidia:latest
```

* * *

#### **4\. Start the Application**

[](https://github.com/rajaram-ramesh/Thunderlake/tree/patch-1#4-start-the-application)

```
# Using Compose v2docker compose up -d# Legacydocker-compose up -d
```

* * *

#### **5\. Verify & Access**

[](https://github.com/rajaram-ramesh/Thunderlake/tree/patch-1#5-verify--access)

```
# See running containersdocker ps# View logsdocker compose logs -fdocker-compose logs -f (legacy) 
```

### **Access the UI:**

-   Direct: \`http://<VM\_PUBLIC\_IP>:8081\`
-   GCP SSH Tunnel:

gcloud compute ssh <INSTANCE\_NAME> --zone -- -L 8081:localhost:8081 -L 8080:localhost:8080

Then browse: [http://localhost:8081](http://localhost:8081/)

> Ensure firewall rules/security groups allow inbound traffic on the exposed ports.

* * *

### Online Documentation

[](https://github.com/rajaram-ramesh/Thunderlake/tree/patch-1#online-documentation)

-   [GitHub Documentation](https://github.com/zetaris/Thunderlake)

* * *
