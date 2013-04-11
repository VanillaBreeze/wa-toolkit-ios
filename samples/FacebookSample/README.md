Facebook Sample
===

This sample shows how to retrieve the information from an ACS claim using Facebook.  You can then use this information to integrate calls to Facebook's graph api.

This sample shows how you can get the number of friends you have (a very useful feature).  The sample was inspired by the [post from Simon Guest](http://simonguest.com/2011/11/11/extracting-and-using-facebook-oauth-token-from-acs/).

## Setup
This sample requires you to setup [Facebook as an Identity Provider in Windows Azure ACS](http://msdn.microsoft.com/en-us/library/windowsazure/gg185919.aspx). In the **FacebookSampleViewController.m** file, you need to replace the ACSNamespace and ACSRealm with your information from the Windows Azure Portal.