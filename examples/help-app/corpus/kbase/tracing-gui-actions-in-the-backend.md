---
source: kbase
url: https://kbase.zetaris.com/knowledge/tracing-gui-actions-in-the-backend
title: "How to trace GUI actions in the backend"
kind: how-to
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: cef276e79b4a5761d853a2f268fb0a6cd6d6511f331c63ccef34747b8af68bbf
---
# How to trace GUI actions in the backend

## What actually happens in the Zetaris backend when certain GUI elements are clicked?

For this example, we will invoke the action of resetting a user password using the GUI and trace what backend commands are executed.

To start, invoke the User Management view of the Administrator console. Then right-click anywhere and choose the **inspect** option.

![](https://kbase.zetaris.com/hubfs/image-png-Aug-01-2022-11-24-17-04-PM.png)

The JavaScript window opens. From the JS menu, choose the **Network** option (which will probably be hidden behind the **\>>** if your screen is not wide enough.

![](https://kbase.zetaris.com/hubfs/image-png-Aug-01-2022-11-25-35-01-PM.png)

Now click the settings icon next to the user whose password you would like to reset and go about things like one normally would (obey the password validation rules, etc.) 

![](https://kbase.zetaris.com/hubfs/image-png-Aug-01-2022-11-28-32-61-PM.png)

Best to clear the buffers prior to executing, as shown above.

Once done, click the query checkbox in the JS window and it will expose the payload sent to the backend engine. as you can see below. 

![](https://kbase.zetaris.com/hubfs/image-png-Aug-01-2022-11-30-09-81-PM.png)

You can use this technique to trace any GUI action to the corresponding CLI / SQL action.
