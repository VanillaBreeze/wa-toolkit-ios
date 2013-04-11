Toolkit Sample
===

This sample shows off all the features in the Toolkit. It allows you to interact with Windows Azure Storage (Blob, Queue and Tables).

## Setup
The plist for the application allows you to choose how you want to connect to Windows Azure. The plist contains a **ToolkitConfig** section. There are three ways to connect that you can choose from:

1. Direct - When you connect direct you will need to supply your account name and account key. You can obtain values from the Windows Azure Portal. You will need to change the **ConnectionType** in the **ToolkitConfig** section to 'Direct'. In the **Direct** section add your account name to **AccountName** and your account key to **DirectAccessKey**.

1. CloudReadySimple - When you connect using the simple proxy (username / password) you set the **ConnectionType** to 'CloudReadySimple'. In the **CloudReadySimple** section you need to set the **ProxyService** section to your proxy service name that you uploaded using a [Cloud Ready Membership Package](https://github.com/windowsazure-toolkits/wa-toolkit-cloudreadypackages). 

1. CloudReadyACS - When you connect using the proxy for ACS you set the **ConnectionType** to 'CloudReadyACS'. In the **CloudReadyACS** section you set the **ACSNamespace** to the namespace you configured in the Windows Azure portal for ACS and **ProxyService** to the service name that you uploaded using a [Cloud Ready Membership Package](https://github.com/windowsazure-toolkits/wa-toolkit-cloudreadypackages). If you use the [Configuraiton Utility](https://github.com/WindowsAzure-Toolkits/wa-toolkit-maccloudconfigutility), you do not need to change the **ACSRealm** section. If you configured this yourself, you will need to change it to match the realm in the Relying party application configured in the Windows Azure Portal.