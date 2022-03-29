// Copyright © 2015 Abhishek Banthia

import Cocoa

class PointingHandCursorButton: NSButton {
    let pointingHandCursor: NSCursor = NSCursor.pointingHand

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: pointingHandCursor)
    }
}
