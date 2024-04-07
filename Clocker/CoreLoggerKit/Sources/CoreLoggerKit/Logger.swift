// Copyright © 2015 Abhishek Banthia

import Cocoa
import os
import os.log
import os.signpost

public class Logger: NSObject {
    let logObjc = OSLog(subsystem: "com.abhishek.Clocker", category: "app")

    public class func log(object annotations: [String: Any]?, for event: NSString) {
        #if DEBUG
            if #available(OSX 10.14, *) {
                os_log(.default, "[%@] - [%@]", event, annotations ?? [:])
            }
        #endif
    }

    public class func info(_ message: String) {
        #if DEBUG
            if #available(OSX 10.14, *) {
                os_log(.info, "%@", message)
            }
        #endif
    }
}

@available(OSX 10.14, *)
public class PerfLogger: NSObject {
    static var panelLog = OSLog(subsystem: "com.abhishek.Clocker",
                                category: "Open Panel")
    static let signpostID = OSSignpostID(log: panelLog)

    public class func disable() {
        panelLog = .disabled
    }

    public class func startMarker(_ name: StaticString) {
        os_signpost(.begin,
                    log: panelLog,
                    name: name,
                    signpostID: signpostID)
    }

    public class func endMarker(_ name: StaticString) {
        os_signpost(.end,
                    log: panelLog,
                    name: name,
                    signpostID: signpostID)
    }
}
