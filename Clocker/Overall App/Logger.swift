// Copyright © 2015 Abhishek Banthia

import Cocoa
import Crashlytics
import os.log
import os.signpost

class Logger: NSObject {
    @objc class func log(object: [String: Any], for key: NSString) {
        Answers.logCustomEvent(withName: key as String,
                               customAttributes: object)
    }
}

@available(OSX 10.14, *)
class PerfLogger: NSObject {
    static let openPanelLog = OSLog(subsystem: "com.abhishek.Clocker", category: "Open Panel")
    static let signpostID = OSSignpostID(log: openPanelLog)

    @objc class func signpostBegin() {
        os_signpost(.begin, log: openPanelLog, name: "Open Panel", signpostID: signpostID)
    }

    @objc class func signpostEnd() {
        os_signpost(.end, log: openPanelLog, name: "Open Panel", signpostID: signpostID)
    }
}
