// Copyright © 2015 Abhishek Banthia

import Cocoa
import Crashlytics
import os.log

class Logger: NSObject {
    @objc class func log(object: [String: Any], for key: NSString) {
        Answers.logCustomEvent(withName: key as String,
                               customAttributes: object)
    }
}
