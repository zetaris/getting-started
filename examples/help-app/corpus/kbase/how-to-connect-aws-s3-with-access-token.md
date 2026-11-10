---
source: kbase
url: https://kbase.zetaris.com/knowledge/how-to-connect-aws-s3-with-access-token
title: "How to connect AWS s3 with access token"
kind: how-to
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: 57a16adce23e50a68acbade5a3c04715d29a3808d394f4da8fc3a52401860a0b
---
# How to connect AWS s3 with access token

1.  Login to zetaris
    
2.  Click on the plus button next to virtual file source.
    
     ![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Sep-24-2025-02-24-40-4838-AM.png)
    
3.  Give name for data source container.click create
    
4.  Find container created and click on the three dots and select create table
    
     ![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Sep-24-2025-02-24-55-9270-AM.png)
    
5.  Select source type as file store and click next.fill the details
    
     ![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Sep-24-2025-02-25-14-6134-AM.png)
    
6.  choose storage as amazon s3 and enter the key including session token . it will show you sample records.
    
     ![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Sep-24-2025-02-25-36-9844-AM.png)
    
7.  then click on create. it will register s3 table with session token.
    
8.  this table will be active till the session is token is valid after that it will fail.
