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

class DraggableClipView: NSClipView {
    private var clickPoint: NSPoint!
    private var originalOrigin: NSPoint!
    private var trackingArea: NSTrackingArea?

    override func mouseDown(with event: NSEvent) {
        print("2")
        super.mouseDown(with: event)
        clickPoint = event.locationInWindow
        originalOrigin = bounds.origin
        print("Click point \(clickPoint!)")

        let keepOn = true
        while keepOn {
            let newEvent = window?.nextEvent(matching: [.leftMouseDragged, .leftMouseUp])
            switch newEvent?.type {
            case .leftMouseDragged:
                print("Hello 1")
                let scale = (superview as? NSScrollView)?.magnification ?? 1.0
                let newPoint = event.locationInWindow
                let newOrigin = NSPoint(x: originalOrigin.x + (clickPoint.x - newPoint.x) / scale,
                                        y: originalOrigin.y + (clickPoint.y - newPoint.y) / scale)
                let constrainedRect = constrainBoundsRect(NSRect(origin: newOrigin, size: bounds.size))
                scroll(to: constrainedRect.origin)
                superview?.reflectScrolledClipView(self)
                return
            default:
                print("Hello2")
            }
        }
    }

    override func mouseDragged(with event: NSEvent) {
        print("1")
        super.mouseDragged(with: event)
        // Account for a magnified parent scrollview.
        let scale = (superview as? NSScrollView)?.magnification ?? 1.0
        let newPoint = event.locationInWindow
        let newOrigin = NSPoint(x: originalOrigin.x + (clickPoint.x - newPoint.x) / scale,
                                y: originalOrigin.y + (clickPoint.y - newPoint.y) / scale)
        let constrainedRect = constrainBoundsRect(NSRect(origin: newOrigin, size: bounds.size))
        scroll(to: constrainedRect.origin)
        superview?.reflectScrolledClipView(self)
    }

    override func mouseUp(with event: NSEvent) {
        print("3")
        super.mouseUp(with: event)
        clickPoint = nil
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        if let trackingArea = self.trackingArea {
            removeTrackingArea(trackingArea)
        }

        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeAlways, .enabledDuringMouseDrag, .inVisibleRect, .activeInKeyWindow]
        let trackingArea = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        addTrackingArea(trackingArea)
    }
}
