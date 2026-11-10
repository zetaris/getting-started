---
source: kbase
url: https://kbase.zetaris.com/knowledge/troubleshoot-if-zetaris-is-hosted-on-internal-network
title: "Troubleshoot if Zetaris is hosted on internal network"
kind: troubleshooting
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: 484fe9c307d895e9f3da575ddd787b4119ddfc139e9bb6a8c730a767ffa66684
---
# Troubleshoot if Zetaris is hosted on internal network

If you are a user in a controlled VPN based environment use the following checks to troubleshoot

 Check 1: Check that Ports are Open, as shown below

![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Nov-23-2023-03-29-58-0079-AM.png)

Check 2:

**Step 1: SSH into your Zetaris Linux vm using Putty or Mac Terminal**

_**example:**_

```
ssh -i "<your_pem_key_name?.pem" <REDACTED> <user_name>@<ip address of Zetaris box>
```

Step 2: **Navigate to the below scripts and make the following replacement**

```
sudo sed -i 's/curl ifconfig.me/hostname -i/g' /home/zetaris/lightning-api/bin/start_lightning_api.sh
```

```
sudo sed -i 's/curl ifconfig.me/hostname -i/g' /home/zetaris/lightning-gui/bin/start_lightning_gui.sh
```
