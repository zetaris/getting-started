---
source: kbase
url: https://kbase.zetaris.com/knowledge/verify-all-zetaris-background-processes-are-running
title: "Verify all Zetaris background processes are running"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: 5705b9e8ab688c3020f2b38e9c70e50f37582f4d5753e9e6479d5f989bc65b38
---
# Verify all Zetaris background processes are running

## If Zetaris does not come up, what is the checklist?

Zetaris runs as a set of intergrated Java processes on a Linux operating system:

-   Zetaris server
-   Zetaris gui
-   Derby (for the repository)
-   Apache solr

Log into the server using SSH, then switch user (su ) to **Zetaris**. If this is a standard install the password will be "zetaris" (all lower case).

![](https://kbase.zetaris.com/hubfs/image-png-Sep-28-2022-03-35-04-07-AM.png)

If all 4 processes are running, the following command should return 4 rows, as shown below.

```
ps -u zetaris | grep java 
```

![](https://kbase.zetaris.com/hubfs/image-png-Sep-28-2022-03-37-31-29-AM.png)

The screenshot above shows 4 running "**java**" processes, so all should be well.

If not, something has gone wrong. The clean way to shut down all processes is to navigate to the bin directory of the server and gui and execute the relevant termination scripts:

### Server Stop:

```
cd /opt/enterprise/server/bin./stop-all.sh
```

![](https://kbase.zetaris.com/hubfs/image-png-Sep-28-2022-03-41-10-26-AM.png)

The above should also stop the apache solr process too.

### GUI Stop:

Navigate to /opt/enterprise/gui/bin, then execute the following:

```
./stop-lightining-gui.sh 
```

What if there is still a java process running?

If there are any java processes after this (run the ps -u zetaris | grep java as shown earlier), then find the process id (the first number from each line of the ps command output and kill the process (example below shows process id 12345 being terminated:

```
kill -9 12345
```

### Server Start:

Navigate back to the server bin and run the start-all script:

```
cd /opt/enterprise/server/bin./start-all.sh
```

The above should result in 3 java processes running (Zetaris server, Derby, solr). Once these are running, start the lightning GUI server

### GUI Start

Navigate to the gui/bin directory and start the lightning GUI process.

```
cd /opt/enterprise/server/bin./start-all.sh./start-lightning-gui.sh
```

### Verify

Run the ps -u command again and you should see 4 java processes running. After about a minute or so, the gui server should be accessible again.

![](https://kbase.zetaris.com/hubfs/image-png-Sep-28-2022-03-52-14-89-AM.png)
