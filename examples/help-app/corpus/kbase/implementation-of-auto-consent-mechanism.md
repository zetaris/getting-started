---
source: kbase
url: https://kbase.zetaris.com/knowledge/implementation-of-auto-consent-mechanism
title: "Implementation of auto consent mechanism"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: da144383f0eefd05ca8c24ea3b9e644fd922f34cc82f5d34ac10cdec42e753f5
---
# Implementation of auto consent mechanism

> For a conceptual understanding please read the following article: [Creating automated consent mechanisms with metadata tagging](https://kbase.zetaris.com/knowledge/creating-automated-consent-mechanisms-with-metadata-tagging)

* * *

### Process

> _Please note that requested access to [![](https://github.githubassets.com/favicon.ico)](https://github.com/zetaris/custsuccess/blob/) GITHUB links will be required in order access files_
> 
> -   Environment [https://ui.trial.enterprise.zetaris.com/](https://ui.trial.enterprise.zetaris.com/)

1.  An admin user will tag columns that contain sensitive personal information with the tag “pii” (Personal Information Identifier)![](https://kbase.zetaris.com/hubfs/image-png-Nov-14-2022-02-07-08-3592-AM.png)
    
2.  A Data Pipeline or Permanent view is created to determine the table metadata and columns with the associated tag “pii”. (refer to [TAG\_METADATA\_VIEW permanent view](https://github.com/zetaris/zetaris_versioncontrol/blob/f6e76a69874f2933324a112b32c1078ea3ae27b5/backup/tag_metadata_view-Permanent_View.sql)) [![](https://kbase.zetaris.com/hubfs/image-png-Nov-14-2022-02-19-19-8129-AM.png)](https://github.com/zetaris/zetaris_versioncontrol/blob/f6e76a69874f2933324a112b32c1078ea3ae27b5/backup/tag_metadata_view-Permanent_View.sql)
    
3.  Additionally, a data pipeline or permanent view is created to determine which IDs from all associated tables must be removed. (refer to [AZURE\_MSSQL\_CUSTOMER\_ID\_CONSENT\_VIEW](https://github.com/zetaris/zetaris_versioncontrol/blob/f6e76a69874f2933324a112b32c1078ea3ae27b5/backup/tag_pipeline-Pipeline.sql)) [![](https://kbase.zetaris.com/hubfs/image-png-Nov-14-2022-02-19-47-4054-AM.png)](https://github.com/zetaris/zetaris_versioncontrol/blob/f6e76a69874f2933324a112b32c1078ea3ae27b5/backup/tag_pipeline-Pipeline.sql)
    
4.  Once these pipeline/permanent views are created. The admin will run the [auto\_consent\_mechanism.py](https://github.com/zetaris/custsuccess/blob/043a1f469df9c0c14febdd8c7aba6b6a0885fd8a/auto_consent_mechanism.py) file, which can be located within the custsuccess repository on our [github](https://github.com/zetaris/custsuccess/blob/043a1f469df9c0c14febdd8c7aba6b6a0885fd8a/auto_consent_mechanism.py).[](https://github.com/zetaris/custsuccess/blob/043a1f469df9c0c14febdd8c7aba6b6a0885fd8a/auto_consent_mechanism.py)
    
5.  The user will be asked to login, using their password and username.
    
6.  The script will generate policies to mask/deny any columns associated with the “pii” tag and additionally provide a filter of the data to remove any id’s where consent has been withdrawn. (This process takes approximately 1 minute and will vary based on table size and number of columns.)
    

![](https://kbase.zetaris.com/hubfs/image-png-Nov-14-2022-11-48-07-9709-PM.png)

8\. Once these policies are created, the administrator will be required to assign these policies to users / roles.![](https://kbase.zetaris.com/hubfs/image-png-Nov-14-2022-11-49-42-7988-PM.png)

* * *

![](blob:https://zetaris.atlassian.net/b3769135-3523-433a-8d5c-9608098e4c0e#media-blob-url=true&id=48546b44-6f36-429d-997a-0e14c4e54636&collection=contentId-2706964520&contextId=2706964520&mimeType=image%2Fpng&name=image-20221107-045342.png&size=63960&height=596&width=770&alt=)Feature Video
