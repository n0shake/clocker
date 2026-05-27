// Copyright © 2026 Adrak Studio LLC

import Cocoa

class PointingHandCursorButton: NSButton {
    let pointingHandCursor: NSCursor = .pointingHand

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: pointingHandCursor)
    }
}
