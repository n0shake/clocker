// Copyright © 2015 Abhishek Banthia

import Cocoa
import os.log
import os.signpost

class Logger: NSObject {
    class func log(object _: [String: Any]?, for _: NSString) {
        // TODO: Use a new analytics solution!
    }
}

@available(OSX 10.14, *)
class PerfLogger: NSObject {
    static var panelLog = OSLog(subsystem: "com.abhishek.Clocker",
                                category: "Open Panel")
    static let signpostID = OSSignpostID(log: panelLog)

    class func disable() {
        panelLog = .disabled
    }

    class func startMarker(_ name: StaticString) {
        os_signpost(.begin,
                    log: panelLog,
                    name: name,
                    signpostID: signpostID)
    }

    class func endMarker(_ name: StaticString) {
        os_signpost(.end,
                    log: panelLog,
                    name: name,
                    signpostID: signpostID)
    }
}
