---
source: kbase
url: https://kbase.zetaris.com/knowledge/how-to-version-control-data-objects-using-git
title: "Version Control mechanism of Zetaris objects using Git"
kind: how-to
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: fe94d1ed6af1b362e4d4bc67e44f3acaca244eec69ed8fdd30bdcd59e9fd5f23
---
# Version Control mechanism of Zetaris objects using Git

## Github Version Control for Zetaris data objects

This page details out the mechanism that Zetaris currently carries out for version controlling of the metastore objects.

Details of different git commands and their uses and the git framework.

![verison_control_git](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/verison_control_git.png)

#### **Push to GitHub repository**

Follow the **yellow circle flow** in the anatomy above

Step 1: A daily/hourly scheduler triggers auto-deploy script.

Step 2: The auto-deploy script will create .sql files with relevant INSERT commands.

Step 3: The git pull/checkout command will upload the above INSERT commands into the Unix local repo.

Step 4: The Unix local repo contains the git config files and performs comparisons to track any changes.

Step 5: Create hourly or daily commit cron commmands to set the frequency of commits.

Step 6: After a change compare merge the changes into the main branch.

Step 7: Apply the commit to the main repo on cloud.

#### Restore from GitHub repository

Follow the **grey circle flow** in the anatomy above

Step 1: When required, trigger the restore script.

Step 2: The restore script will retrieve the latest version of the objects in the git repo.

Step 3: The pull/checkout command will bring the scripts into the local Unix box.

Step 4: The objects are pulled and stored as .sql files in a /restore directory.

Step 5: Auto-deploy scripts pick up the .sql files and execute them.

Step 6: On execution , existing objects are deleted and previous version of the opbjects are recreated.

Step 7: Restart the server (if required) to make the changes effective.

### Specifications

#### Usage

There will be 2 master scripts that will wrap around all of the above functionalities

Push to GitHub repository: crontab + git-push-files.sh

Restore from GitHub repository: git\_restore.sh

#### Behaviour

The git\_push script should be scheduled whereas the git\_restore should be an on-demand script. The script should be able to function according to the number of parameters provided.

If only the object type (pipeline/datamart/view) is provided then it should pick all information/containers pertaining to that particular object type.

If the container name is provided then just the specific container should be taken into account.

#### Variations

git-push-files.sh <pipeline/datamart/view> <container name>

git-restore.sh <pipeline/datamart/view> <container name>

#### Style

Styling not required until placed on UI
