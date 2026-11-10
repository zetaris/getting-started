---
source: kbase
url: https://kbase.zetaris.com/knowledge/how-to-create-spark-and-presto-engines
title: "How to create spark and presto engines"
kind: how-to
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: 69b0a0cfc530be7f1516f001ce29b3e6a326183fca81724592440a915c2d9f09
---
# How to create spark and presto engines

1.  Login to zetaris
    
2.  click on compute engine tab
    
    ![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Sep-24-2025-02-09-40-8302-AM.png) 
    
3.  compute engine side screen will open. click on plus button.
    
    ![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Sep-24-2025-02-10-28-1275-AM.png)
    
4.  Screen will open where details need to be filled. In that select presto or spark as engine. fill the driver cores and memory cores
    
    ![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Sep-24-2025-02-11-07-0184-AM.png)  
    
5.  Once all the details are filled. click on create
    
6.  This will create a spark engine.
    
     ![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Sep-24-2025-02-11-33-5617-AM.png)
    
7.  In order to run the query on this spark engine. you can either:
    
    1.  click on three dots and select “set as default” now all the query will run on this compute engine.
        
         ![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Sep-24-2025-02-11-58-1860-AM.png)
        
    2.  you can also select default from sql workplace screen. then any query you will run will be directed to newly created spark engine
        
         ![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Sep-24-2025-02-12-23-6045-AM.png)
        
    3.  also you can run query by execute by explicitly mentioning the new spark engine name
        
        1.  SELECT \* FROM TPCDS\_DBA.call\_center **using spark mspark**
            
8.  To update engine configs you can click on three dots on right of spark engine and select “details”.
    
     ![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Sep-24-2025-02-12-42-5344-AM.png)
    
9.  Then further select deatils tab where you can update the configs of engine.
    
    ![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Sep-24-2025-02-13-04-4286-AM.png) 
    
10.  “presto” engine can be created same as spark engine. all you have to do different is while creating select “presto engine”
    
    ![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Sep-24-2025-02-13-25-0692-AM.png)
