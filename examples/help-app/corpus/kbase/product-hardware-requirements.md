---
source: kbase
url: https://kbase.zetaris.com/knowledge/product-hardware-requirements
title: "Product Hardware Requirements"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: 3eefb6eabcbd5f2c7922be1be886565f7dc353f1114b3a585bb974addfe6d58a
---
# Product Hardware Requirements

## Virtual Machines (VMs), Virtual Networks (VNets), and Zetaris' compute requirements.

### Virtual Machines (VMs) & Virtual Networks (VNets)

Azure Virtual Machine (VM) will serve the compute requirements for running the Zetaris Application server. The VM setup involves two VMs paired over Azure Virtual Network (VNet) to enable configuration and provide an added layer of security via disabling direct access to the Zetaris host VM (vt-zetaris-01). This will be setup by the client’s IT Team.

Virtual Machine: vt-zetaris-01

Operating System: CentOS 8

Description: This virtual machine will host the Zetaris web server. It's a headless VM (no-desktop) and will be accessed via Azure Bastion service.

Configuration: 4 vCPU, 32GB RAM, 256GB SSD

VNet/subnet: vnet-test-client/sn-poc-zetaris

Virtual Machine: vt-zetaris-mgmt

Operating System: Window 10

Description: The web server hosted on vt-zetaris-01  will be accessed via Internet Explorer available on the Windows 10 VM below. This VM will also be accessed via Azure Bastion service.

Configuration: 2 vCPU, 4GB RAM, 128GB SSD

VNet/subnet: vnet-test-client/sn-poc-zetaris

#### Virtual Machine Authentication Strategy

It is suggested that the client may deploy Azure Bastion service. The service will be utilised for authenticating users on the above virtual machines. The virtual machine credentials are shared with Zetaris consultants/engineers via LastPass. The VMs will not allow authentication via AAD for added security.

### Access Security via Azure IAM

Coupled with other aspects of the design such as subscription structure and resource groups strategy. Azure AD’s B2B collaboration feature will be used to provide the client’s and Zetaris engineers access to the Azure Subscriptions in a least privileged manner using guest AD accounts.

With B2B collaboration, the client can securely share their applications and services with guest users from partner organizations, while maintaining control over their own corporate data. The Zetaris engineers will use their existing AD identities and credentials to login to the client’s Azure subscription.
