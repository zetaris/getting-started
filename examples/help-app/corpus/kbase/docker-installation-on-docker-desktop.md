---
source: kbase
url: https://kbase.zetaris.com/knowledge/docker-installation-on-docker-desktop
title: "Docker Desktop installation using images distributed via Docker hub"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: b37296d8488a538b7a466248d9253af84ae8b9e8785566a02d4453d21927b06d
---
# Docker Desktop installation using images distributed via Docker hub

## This documentation enables the user to run the zetaris images on a freemium container on your docker desktop.

**Pre-Requisites**:

You have installed the latest version of [Docker Desktop.](https://docs.docker.com/get-docker/)

You have installed a [Git client](https://git-scm.com/downloads).

For  ![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Dec-19-2023-02-37-19-1416-AM.png) users 

Once you have installed docker , check these settings on WSL 

![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Dec-19-2023-02-02-36-7277-AM.png)

Please check your wsl version using the below command

```
wsl --version
```

![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Apr-23-2024-01-22-19-6812-AM.png)In case you need to upgrade WSL , please use the below command in ![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Dec-19-2023-02-37-19-1416-AM.png) PowerShell

```
wsl --install
```

#### For verifying your Docker set-up

In ![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Dec-19-2023-02-37-19-1416-AM.png) PowerShell , type the below command and check that you can see a version >24.0

```
docker --version
```

![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Apr-23-2024-01-20-00-7826-AM.png)

#### Setup:

Pull the latest Freemium image for zetaris github repo

```
git clone https://github.com/zetaris/Freemium.git
```

#### Login to docker repo:

Login to Docker to get authenticated by running the commands below in a Windows Powershell

Your access to the zetaris docker containers will be activated within 24 hours of request.

```
docker  login
```

#### Start docker:

![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Dec-19-2023-02-37-42-0838-AM.png) specific

On windows , we need to convert the files to unix mode. In the Windows Powershell ,ensure that you are in the path of the cloned repo eg : C:\\Users\\john.doe\\Freemium

```
windows_convert.sh
```

**Start  the containers**:

In the Windows Powershell ,ensure that you are in the path of the cloned repo eg : C:\\Users\\john.doe\\Freemium.

Now we can pull the images by running

```
docker-compose pull
```

```
docker-compose up
```

**Check if all 4 containers for freemium are in 'running' state on the Docker Desktop**

 **![image (6)](https://kbase.zetaris.com/hs-fs/hubfs/image%20(6).png)**

**Run the admin id creation script :**

In a **new**  Windows Powershell terminal ,ensure that you are in the path of the cloned repo

eg : C:\\Users\\john.doe\\Freemium , execute the below script

```
docker-compose exec -it zetaris-db /scripts/generate_default_dev_users.sh
```

#### Your Docker desktop is now ready

![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Dec-19-2023-02-27-33-6980-AM.png)

Use the url  highlighted below to login to the Zetaris user interface with the user id

![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Dec-19-2023-02-32-28-5086-AM.png)

```
User ID: <REDACTED>
```

```
Password: <REDACTED>
```

**Troubleshooting**

The driver docker image might seems to fail if the images don't execute in the correct order, if the above warning keeps going, you may go to docker desktop console to restart it if it hangs You just need to restart the zetaris-server only until it starts successfully

**Uninstalling**:

To uninstall the docker container use the below command from within the repo directory eg: C:\\Users\\john.doe\\Freemium

```
docker compose down
```
