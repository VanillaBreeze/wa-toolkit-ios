Deprecated
===

##This Toolkit is now deprecated and is superseded by [Windows Azure Mobile Services](http://www.windowsazure.com/ios).

The Windows Azure Toolkit for iOS provided developers with the first iteration of support for building backend services for iOS apps using Windows Azure.  The main areas of feedback we received from mobile developers was that they wanted a turn-key set of services for common functionality such as notifications, auth, and data.  [Windows Azure Mobile Services](http://www.windowsazure.com/ios) directly reflects this feedback by enabling developers to simpily provision, configure, and consume scalable backend services.  All future improvements will be channeled into Windows Azure Mobile Services rather than this toolkit.

To get started with Mobile Services, [sign up](http://www.windowsazure.com/en-us/pricing/free-trial/) for a Windows Azure accound and receive 10 free Mobile Services.


---
##Windows Azure Toolkit for iOS (Library)

The Windows Azure Toolkit for iOS is a toolkit for developers to make it easy to access Windows Azure storage services from native iOS applications.  The toolkit can be used for both iPhone and iPad applications, developed using Objective-C and XCode.  

The toolkit works in two ways – the toolkit can be used to access Windows Azure storage directly, or alternatively, can go through a proxy server.  The proxy server code is the same code as used in the WP7 toolkit for Windows Azure (found here) and negates the need for the developer to store the Azure storage credentials locally on the device.  If you are planning to test using the proxy server, you’ll need to download and deploy the services found in the [cloudreadypackages](https://github.com/windowsazure-toolkits/wa-toolkit-cloudreadypackages) here on GitHub.  

The Windows Azure Toolkit for iOS is made available as an open source product under the Apache License, Version 2.0.  

## Windows Azure Mobile Services

> If you're just getting started looking at connecting an iOS application to Windows Azure, you will also want to look at [Windows Azure Mobile Services](https://www.windowsazure.com/en-us/develop/mobile/).  Mobile Services allows you to quickly spin up a Windows Azure backend which you can then connect with your iOS application to make use of easy SQL Database powered data storage, user authentication, push notifications, and more.  This effectively replaces the need to use a cloud ready package.  At this time, the Mobile Services iOS SDK ([available on GitHub](https://github.com/WindowsAzure/azure-mobile-services)) does not feature full blob, table, or queue support.  For this features, continue with the Windows Azure Toolkit for iOS.

## Downloading the Library

To download the library, select a download package (e.g. v1.2.1).  The download zip contains binaries for iOS 4.3, targeted for both the simulator and devices.  Alternatively, you can download the source and compile your own version.  The project file has been designed to work with XCode 4.

## Logging

You can enable logging for the library when you are working with it in debug mode by setting an environment variable for your run.
Go into your project schema and add the environment variable WALogging and set it to YES and logging information will print in the console.

## Using the Library in your application

CocoaPods
-------------------
The toolkit can be installed using [CocoaPods](http://cocoapods.org/). See the site to get CocoaPods installed. Here is an example of a pod file for the toolkit:

		platform :ios
		pod 'watoolkitios', '~> 1.5'

Xcode 4.x (library)
-------------------
1. Open the watoolkit-lib Xcode project.
1. Compile the project for release.
1. Place the .a file and the header files somewhere that you can reference from your project (for this example lets say lib).
1. Click on your project's name in the sidebar on the left to open the project settings view in the right pane of the window.
1. In the middle pane you will see **PROJECT** and **TARGETS** headers for your project. Click on your project name, then select **Build Settings** along the top to open the Build Settings editor for your entire project.
1. Find the **Header Search Paths** setting. Double click and add a new entry. Add a search path to the directory you have the header files for the static library and check the `Recursive` checkbox. Also add `/usr/include/libxml2` to the search path and check `Recursive`.
	* Find the **Library Search Paths** setting. Double click and add a new entry. Add a search path to the **libwatoolkitios.a** file for the library directory you have for your project.
1. Find the **Other Linker Flags** entry and double click it. Use the **+** button to add a new entry and enter `-ObjC -all_load`. Dismiss the editor with the **Done** button.
1. Locate the target you wish to add Windows Azure iOS Toolkit to in the **TARGETS** list in the middle of the editor pane. Select it to open the target settings editor in the right pane of the window.
1. Click the **Build Phases** tab along the top of the window to open the Build Phases editor.
1. Click the disclosure triangles next to the **Target Dependencies** and **Link Binary with Libraries** items.
1. In the **Target Dependencies** section, click the **+** button to open the Target selection sheet. Click on the **libwatoolkitios.a** target and click the **Add** button to create a dependency.
1. In the **Link Binary with Libraries** section, click the **+** button to open the Library selection sheet. Here we need to instruct the target to link against all the required watoolkitios-lib libraries and one system libraries. Select each of the following items (one at a time or while holding down the Command key to select all of them at once) and then click the **Add** button:
	* **libwatoolkitios.a**
	* **libxml2.2.dylib**
1. Verify that all of the libraries are showing up in the **Link Binary with Libraries** section before continuing.

Xcode 4.x (Git Submodule)
-------------------------

1. Add the submodule: `git submodule add git://github.com/WindowsAzure-Toolkits/wa-toolkit-ios.git watoolkitios`
1. Open the project you wish to add the Windows Azure iOS library to in Xcode.
1. Focus your project and select the "View" menu > "Navigators" > "Project" to bring the project file list into view.
1. Drag the **watoolkitios-ib.xcodeproj** file from the Finder and drop it on your "(Your Project's Name)".xcodeproj.
1. Click on your project's name in the sidebar on the left to open the project settings view in the right pane of the window.
1. In the middle pane you will see **PROJECT** and **TARGETS** headers for your project. Click on your project name, then select **Build Settings** along the top to open the Build Settings editor for your entire project.
1. Find the **Header Search Paths** setting. Double click and add a new entry. Add a search path to the `$(BUILT_PRODUCTS_DIR)` directory and check the `Recursive` checkbox. Also add `/usr/include/libxml2` to the search path and check `Recursive`.
	* **NOTE**: This is only necessary if you are **NOT** using DerivedData. 
	* Find the **Library Search Paths** setting. Double click and add a new entry. Add a search path to the `"$(BUILT_PRODUCTS_DIR)/Build/$(BUILD_STYLE)-$(PLATFORM_NAME)"` directory you have added to your project.  
1. Find the **Other Linker Flags** entry and double click it. Use the **+** button to add a new entry and enter `-ObjC -all_load`. Dismiss the editor with the **Done** button.
1. Locate the target you wish to add Windows Azure iOS Toolkit to in the **TARGETS** list in the middle of the editor pane. Select it to open the target settings editor in the right pane of the window.
1. Click the **Build Phases** tab along the top of the window to open the Build Phases editor.
1. Click the disclosure triangles next to the **Target Dependencies** and **Link Binary with Libraries** items.
1. In the **Target Dependencies** section, click the **+** button to open the Target selection sheet. Click on the **watoolkitios-lib** target and click the **Add** button to create a dependency.
1. In the **Link Binary with Libraries** section, click the **+** button to open the Library selection sheet. Here we need to instruct the target to link against all the required watoolkitios-lib libraries and one system libraries. Select each of the following items (one at a time or while holding down the Command key to select all of them at once) and then click the **Add** button:
    * **libwatoolkitios.a**
    * **libxml2.2.dylib**
1. Verify that all of the libraries are showing up in the **Link Binary with Libraries** section before continuing.

Congratulations, you are now done adding Windows Azure iOS toolkit into your Xcode 4 based project!

You now only need to add includes for the Windows Azure iOS toolkit libraries at the appropriate places in your application. The relevant includes are:

    #import "watoolkitios-lib/WAToolkit.h"
    
Please see the samples directory for details on utilizing the library.

## Documentation

Install [appledoc](https://github.com/tomaz/appledoc) from gentlebytes github and run library/MakeDocumenation.  This will create a doc set and install it to Xcode. There are some issues with cross reference links that we are working to fix.

## Samples

The samples directory contains samples of using the Toolkit. Each sample has a readme that explains how to use it.

## Other Projects

The following are the other projects associated with this project:

1. [Toolkit Configuration Utility](https://github.com/WindowsAzure-Toolkits/wa-toolkit-maccloudconfigutility) - This utility helps when using the [Cloud Ready Packages](https://github.com/windowsazure-toolkits/wa-toolkit-cloudreadypackages). 
1. [Cloud Ready Packages](https://github.com/windowsazure-toolkits/wa-toolkit-cloudreadypackages) - These are the packages to upload to act as proxies between your application and Windows Azure.

## Contact

For additional questions or feedback, please contact the [team](mailto:chrisner@microsoft.com).
