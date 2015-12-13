Apptentive iOS SDK
==================

This iOS library allows you to add a quick and easy in-app-feedback mechanism
to your iOS applications. Feedback is sent to the Apptentive web service.

Quickstart
==========

There are no external dependencies for this SDK.

Sample Application
------------------
The sample application FeedbackDemo demonstrates how to integrate the SDK
with your application.

The demo app includes the normal feedback flow, which can be activated by
clicking the Feedback button. It's a one screen process which can gather
feedback, an email address, and even a screenshot:

![Feedback Screen](etc/screenshots/feedback_iphone.png?raw=true)

The rating flow can be activated by clicking on the Ratings button. It asks
the user if they are happy with the app. If not, then a simplified feedback
window is opened. If they are happy with the app, they are prompted to rate
the app in the App Store:

![Popup](etc/screenshots/rating.png?raw=true)


Required Frameworks
-------------------
In order to use `ApptentiveConnect`, your project must link against the
following frameworks:

* CoreGraphics
* CoreTelephony
* Foundation
* QuartzCore
* StoreKit
* SystemConfiguration
* UIKit

Project Settings for Xcode 4
----------------------------
The instructions below are for source integration. For binary releases, see our [Binary Distributions](https://github.com/apptentive/apptentive-ios/wiki/Binary-Distributions) page.

There is a video demoing integration in Xcode 4 here:
http://vimeo.com/23710908

Drag the `ApptentiveConnect.xcodeproj` project to your project in Xcode 4 and
add it as a subproject. You can do the same with a workspace.

In your target's `Build Settings` section, add the following to your 
`Other Linker Flags` settings:

    -ObjC -all_load

In your target's `Build Phases` section, add the `ApptentiveConnect` and
`ApptentiveResources` targets to your `Target Dependencies`.

Then, add `libApptentiveConnect.a` to `Link Binary With Libraries`

Build the `ApptentiveResources` target for iOS devices. Then, add the
`ApptentiveResources.bundle` from the `ApptentiveConnect` products in the
file navigator into your `Copy Bundle Resources` build phase. Building
for iOS devices first works around a bug in Xcode 4.

Now, drag `ATConnect.h` from `ApptentiveConnect.xcodeproj` to your app's 
file list.

Now see "Using the Library", below, for instructions on using the library in your code.

Using the Library
-----------------

`ApptentiveConnect` queues feedback and attempts to upload in the background. This
is intended to provide as quick a mechanism for submitting feedback as possible.

In order for queued/interrupted feedback uploads to continue uploading, we 
recommending instantiating `ATConnect` and setting the API key at application
startup, like:

``` objective-c
#include "ATConnect.h"
// ...
- (void)applicationDidFinishLaunching:(UIApplication *)application /* ... */ {
    ATConnect *connection = [ATConnect sharedConnection];
    connection.apiKey = kApptentiveAPIKey;
    // ...
}
```

Where `kApptentiveAPIKey` is an `NSString` containing your API key. As soon
as you set the API key on the shared connection object, any queued feedback
will start to upload, pending network availability. You also should not have
to set the API key again on the shared connection object.

Now, you can show the Apptentive feedback UI from a `UIViewController` with:

``` objective-c
#include "ATConnect.h"
// ...
ATConnect *connection = [ATConnect sharedConnection];
[connection presentFeedbackControllerFromViewController:self];
```

Easy!


App Rating Flow
---------------
`ApptentiveConnect` now provides an app rating flow similar to other projects
such as [appirator](https://github.com/arashpayan/appirater). This uses the number
of launches of your application, the amount of time users have been using it, and
the number of significant events the user has completed (for example, levels passed)
to determine when to display a ratings dialog.

To use it, add the `ATAppRatingFlow.h` header file to your project.

Then, at startup, instantiate a shared `ATAppRatingFlow` object with your 
iTunes app ID (see "Finding Your iTunes App ID" below):

``` objective-c
#include "ATAppRatingFlow.h"
// ...
- (void)applicationDidFinishLaunching:(UIApplication *)application /* ... */ {
    ATAppRatingFlow *sharedFlow = [ATAppRatingFlow sharedRatingFlowWithAppID:@"<your iTunes app ID>"];
    // The parameter is a BOOL indicating whether a rating dialog can be 
    // shown here.
    [sharedFlow appDidLaunch:YES viewController:self.navigationController];
    
    // ...
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    ATAppRatingFlow *sharedFlow = [ATAppRatingFlow sharedRatingFlowWithAppID:@"<your iTunes app ID>"];
    [sharedFlow appDidEnterForeground:YES viewController:self.navigationController];
}
```

The `viewController` parameter is necessary in order to be able to show the 
feedback view controller if a user is unhappy with your app.

If you're using significant events to determine when to show the ratings flow, you can
increment the number of significant events by calling:

```
[sharedFlow userDidPerformSignificantEvent:canPromptForRating viewController:aViewController];
```

Above, `canPromptForRating` is a `BOOL` indicating whether the user could be prompted for a rating then and there, and `aViewController` is a `UIViewController` from which to display the feedback view controller if the user is unhappy with your app.


You can also choose to show the dialog manually:

``` objective-c
ATAppRatingFlow *sharedFlow = [ATAppRatingFlow sharedRatingFlowWithAppID:kApptentiveAppID];
[sharedFlow showEnjoymentDialog:aViewController];
```

This is helpful if you want to implement custom triggers for the ratings 
flow.

You can modify the parameters which determine when the ratings dialog will be
shown in your app settings on apptentive.com.


Metrics
-------
Metrics provide insight into exactly where people begin and end interactions
with your app and with feedback, ratings, and surveys. You can enable and disable
metrics on your app settings page on apptentive.com.


Surveys
-------
To use surveys, add the `ATSurveys.h` header to your project.

You can check for available surveys after having set up `ATConnect` (see above)
by calling `[ATSurveys checkForAvailableSurveys]` and registering for the
`ATSurveyNewSurveyAvailableNotification` notification. Then, you may present a 
survey by calling `[ATSurveys presentSurveyControllerFromViewController:vc]`,
where `vc` is the view controller which will present the survey.

For example:

```objective-c
#include "ATSurveys.h"
// ...
- (void)applicationDidFinishLaunching:(UIApplication *)application /* ... */ {
    // ...
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(surveyBecameAvailable:) name:ATSurveyNewSurveyAvailableNotification object:nil];
	[ATSurveys checkForAvailableSurveys];
}

- (void)surveyBecameAvailable:(NSNotification *)notification {
	// Present survey here as appropriate.
}
```


**Finding Your iTunes App ID**
In [iTunesConnect](https://itunesconnect.apple.com/), go to "Manage Your 
Applications" and click on your application. In the "App Information" 
section of the page, look for the "Apple ID". It will be a number. This is
your iTunes application ID.

Contributing
------------
We love contributions!

Any contributions to the master apptentive-ios project must sign the [Individual Contributor License Agreement (CLA)](https://docs.google.com/a/apptentive.com/spreadsheet/viewform?formkey=dDhMaXJKQnRoX0dRMzZNYnp5bk1Sbmc6MQ#gid=0). It's a doc that makes our lawyers happy and ensures we can provide a solid open source project.

When you want to submit a change, send us a [pull request](https://github.com/apptentive/apptentive-ios/pulls). Before we merge, we'll check to make sure you're on the list of people who've signed our CLA.

Thanks!
