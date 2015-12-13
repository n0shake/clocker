2015-02-28 pkamb v0.4.12
--------------------------
This release removes a request to access the OS X Contacts list to pre-fill the Feedback Dialog form.

The Contacts permission request was unexpected to some developers and users. This will be re-added as an option in the future.

2014-12-05 wooster v0.4.11
--------------------------
Fixes problem where prompting on launch would never work.

This was a regression due to a bad merge.

2012-10-08 wooster v0.4.8
-------------------------

Fixing APPTENTIVE-571, in which custom app data wasn't being sent with feedback.

2012-09-19 wooster v0.4.7
-------------------------
The big change here is a switch to git subtrees from a submodule for the copy of apptentive-ios in the project. This makes checking out the project and getting started much easier.

Changes:

* Fix for ratings dialog not showing up due to reachability failing.
* OSX-6 Switch to git subtrees for apptentive-ios

2012-08-29 wooster v0.4.6
-------------------------
Changes:

* Pulled in v0.4.5 of apptentive-ios.
* Went from JSONKit to PrefixedJSONKit.
* Removed methods for displaying different feedback window types on OS X.
* Added placeholder text in feedback window.
