Apptentive Mac SDK
==================

This Cocoa library for OS X allows you to add a quick and easy in-app-feedback
mechanism to your Mac applications. Feedback is sent to the Apptentive web
service.

Quickstart
==========

Sample Application
------------------
The sample application FeedbackDemo demonstrates how to integrate the SDK
with your application.


Required Frameworks
-------------------
In order to use `ApptentiveConnect`, your project must link against the
following frameworks:

* AppKit
* CoreGraphics
* Foundation
* QuartzCore
* SystemConfiguration

Project Settings for Xcode 4
----------------------------

Check out the `apptentive-osx` project from GitHub. You'll either want to put it in a
sub-folder of your project or, if you use `git`, add it as a [git submodule](http://help.github.com/submodules/).

In your target's `Build Settings` section, add the following to your Other Linker Flags settings:

`-ObjC -all_load`

Then, open your project in Xcode and drag the `ApptentiveConnect.xcodeproj` project file 
to your project:

![Step 1](https://raw.github.com/apptentive/apptentive-osx/master/etc/screenshots/integration_step1.png)

In your apps' target settings, add `ApptentiveConnect` to the "Target Dependencies" build phase:

![Step 2](https://raw.github.com/apptentive/apptentive-osx/master/etc/screenshots/integration_step2.png)

Next, add `ApptentiveConnect.framework` to the "Link Binary With Libraries" build phase:

![Step 3](https://raw.github.com/apptentive/apptentive-osx/master/etc/screenshots/integration_step3.png)

Finally, drag the `ApptentiveConnect.framework` from the `ApptentiveConnect` project to the 
"Copy Bundle Resources" build phase:

![Step 4](https://raw.github.com/apptentive/apptentive-osx/master/etc/screenshots/integration_step4.png)

Using the Library
-----------------

`ApptentiveConnect` queues feedback and attempts to upload in the background. This
is intended to provide as quick a mechanism for submitting feedback as possible.

In order for queued/interrupted feedback uploads to continue uploading, we 
recommending instantiating `ATConnect` and setting the API key at application
startup, like:

``` objective-c
#import <ApptentiveConnect/ATConnect.h>
// ...
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    ATConnect *connection = [ATConnect sharedConnection];
    connection.apiKey = kApptentiveAPIKey;
    // ...
}
```

Where `kApptentiveAPIKey` is an `NSString` containing your API key. As soon
as you set the API key on the shared connection object, any queued feedback
will start to upload, pending network availability. You also should not have
to set the API key again on the shared connection object.

Now, you can show the Apptentive feedback UI with:

``` objective-c
#import <ApptentiveConnect/ATConnect.h>
// ...
ATConnect *connection = [ATConnect sharedConnection];
[connection showFeedbackWindow:sender];
```

Easy!

App Rating Flow
---------------
`ApptentiveConnect` now provides an app rating flow similar to other projects
such as [appirator](https://github.com/arashpayan/appirater). To use it, add
the `ATAppRatingFlow.h` header file to your project.

Then, at startup, instantiate a shared `ATAppRatingFlow` object with your 
iTunes app ID (see "Finding Your iTunes App ID" below):

``` objective-c
#import <ApptentiveConnect/ATAppRatingFlow.h>
// ...
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [[ATConnect sharedConnection] setApiKey:kApptentiveAPIKey];
    ATAppRatingFlow *ratingFlow = [ATAppRatingFlow sharedRatingFlowWithAppID:kApptentiveAppID];
    [ratingFlow appDidLaunch:YES];
}
```

You can also choose to show the dialog manually:

``` objective-c
ATAppRatingFlow *ratingFlow = [ATAppRatingFlow sharedRatingFlowWithAppID:kApptentiveAppID];
[ratingFlow showEnjoymentDialog:sender];
```

This is helpful if you want to implement custom triggers for the ratings 
flow.

**Finding Your iTunes App ID**
In [iTunesConnect](https://itunesconnect.apple.com/), go to "Manage Your 
Applications" and click on your application. In the "App Information" 
section of the page, look for the "Apple ID". It will be a number. This is
your iTunes application ID.
