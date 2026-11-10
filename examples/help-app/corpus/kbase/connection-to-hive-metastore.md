---
source: kbase
url: https://kbase.zetaris.com/knowledge/connection-to-hive-metastore
title: "Hive metastore"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: b0a47bda70c529fc650f9e9839e8f478c21edbe73c572618ac1261f967349962
---
# Hive metastore

### Steps for connecting to Hive Meta Store:

1.  Login to your Zetaris environment.
2.  Click on **'NDP Fabric Builder'** on the top left side of the screen.
3.  Click on the plus button next to 'Hive Meta Store'.  
     ![](https://kbase.zetaris.com/hubfs/image-png-Jul-27-2022-03-18-01-27-AM.png)  
    
4.  A pop-up will appear. Fill all the details in the pop-up and click '**Next'.**
    
    1.  Metastore name : Can be any name
    2.  JDBC URL : JDBC URL of hive metastore
    3.  JDBC Username : Your hive username
    4.  JDBC Password : <REDACTED> hive password
    5.  Prefix : Can be anything name. This field is optional
    
      
    ![](https://kbase.zetaris.com/hubfs/image-png-Jul-27-2022-03-22-08-38-AM.png)  
    
5.  Select the database you want to register. If no database is selected, all the databases will be registered.  
    ![](https://kbase.zetaris.com/hubfs/image-png-Jul-27-2022-03-23-28-91-AM.png)
    
    ![](blob:https://zetaris.atlassian.net/734bd0c4-3de4-453e-824c-7b20c889eacc#media-blob-url=true&id=1a194640-a513-4c42-b2df-d70b86727812&collection=contentId-2656108545&contextId=2656108545&mimeType=image%2Fpng&name=image-20220727-030817.png&size=43332&height=461&width=699&alt=)
    
6.  Click **'Register'**.
7.  A newly created hive connection will appear under 'Hive Meta Store'.  
    ![](https://kbase.zetaris.com/hubfs/image-png-Jul-27-2022-03-24-30-50-AM.png)  
    
8.  Hive tables can be previewed by clicking on **'Preview'** button.  
    
    ![](https://kbase.zetaris.com/hubfs/image-png-Jul-27-2022-03-17-21-01-AM.png)  
    
9.  As a quick test, you can navigate to the '**Schema Store View'** tab, and run a similar SQL query shown below.  
    
    ![](https://kbase.zetaris.com/hubfs/image-png-Jul-27-2022-03-28-42-93-AM.png)
    
    ![](blob:https://zetaris.atlassian.net/9427135b-666a-4166-86e0-f111d6e943da#media-blob-url=true&id=e3ce3292-6ec3-41a9-983b-233e02e23064&collection=contentId-2656108545&contextId=2656108545&mimeType=image%2Fpng&name=image-20220727-031344.png&size=12073&height=169&width=759&alt=)
