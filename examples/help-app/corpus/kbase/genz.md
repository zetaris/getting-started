---
source: kbase
url: https://kbase.zetaris.com/knowledge/genz
title: "GenZ"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: ca29db5378d6fae0f507f47d0242ee3111b5cb1b457d2af6f993129b4865c768
---
# GenZ

## Use this article to help understand how to connect and use the Zetaris Enterprise ChatBot, GenZ

### Docker Guide

#### Step 1: Access GenZ

Confirming that PrivateAI is running, you are able to connect to the application by going to the following url (assuming it is locally hosted):

```
http://localhost:3001
```

#### Step 2: Enter Credentials

Enter the following information

**Zetaris API URL:** http://zetaris-api:8888

**Email:** <user email address>

**Password:<REDACTED> <user password>

**Organisation:** 23

![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-May-16-2024-01-03-34-4851-AM.png)

### Step 3: Select Data and Write Questions

1\. Select **Structured**

2\. Choose which **Data Mart** you want to question (Data Mart needs to already be built)

3\. Select which table or tables you want to include in your questioning.

3\. Select **Prescriptive** or **Descriptive**

4\. Start writing questions :)

NOTE: Docker install is meant for testing and small-scale analysis only, as all compute is run locally. Best performance is seen when leveraging NVIDIA or Intel GPU chips.

For enterprise questioning and testing, select our Zetaris Enterprise, from the Product list, and deploy on a larger environment.
