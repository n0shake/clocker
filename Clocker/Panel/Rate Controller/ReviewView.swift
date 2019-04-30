// Copyright © 2015 Abhishek Banthia

import Cocoa

class ReviewView: NSView {
    private var trackingArea: NSTrackingArea?

    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        let dismissalButton = subviews.filter({ $0.tag == 55 }).first
        if let firstMatch = dismissalButton, firstMatch.isHidden {
            firstMatch.isHidden = false
        }
    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        let dismissalButton = subviews.filter({ $0.tag == 55 }).first
        if let firstMatch = dismissalButton, !firstMatch.isHidden {
            firstMatch.isHidden = true
        }
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        if let trackingArea = self.trackingArea {
            removeTrackingArea(trackingArea)
        }

        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeAlways]
        let trackingArea = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        addTrackingArea(trackingArea)
    }
}
