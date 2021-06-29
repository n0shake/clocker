// Copyright © 2015 Abhishek Banthia

import Cocoa

class UpcomingEventView: NSView {
    private var trackingArea: NSTrackingArea?

    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        let dismissalButton = subviews.filter { $0.tag == 55 }.first
        if let firstMatch = dismissalButton, firstMatch.isHidden {
            firstMatch.isHidden = false
        }
    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        let dismissalButton = subviews.filter { $0.tag == 55 }.first
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

class ModernSliderContainerView: NSView {
    private var trackingArea: NSTrackingArea?
    public var currentlyInFocus = false

    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        currentlyInFocus = true
    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        currentlyInFocus = false
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

class ThinScroller: NSScroller {
    private var trackingArea: NSTrackingArea?

    override class func scrollerWidth(for _: NSControl.ControlSize, scrollerStyle _: NSScroller.Style) -> CGFloat {
        return 15
    }

    override class func awakeFromNib() {
        super.awakeFromNib()
    }

    override func drawKnobSlot(in _: NSRect, highlight _: Bool) {
        // Leaving this empty to prevent background drawing
    }

    override func drawKnob() {
        let knobRect = rect(for: .knob)
        let knobDimensions: CGFloat = 10.0
        let newRect = NSMakeRect(knobRect.origin.x, knobRect.origin.y + 5, knobDimensions, knobDimensions)
        let path = NSBezierPath(ovalIn: newRect)
        NSColor.lightGray.set()
        path.fill()
    }
}
