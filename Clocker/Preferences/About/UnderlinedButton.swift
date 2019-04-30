// Copyright © 2015 Abhishek Banthia

import Cocoa

class UnderlinedButton: NSButton {
    var cursor: NSCursor? = NSCursor.pointingHand

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }

    override func resetCursorRects() {
        if let pointingHandCursor = cursor {
            addCursorRect(bounds, cursor: pointingHandCursor)
        } else {
            super.resetCursorRects()
        }
    }
}
