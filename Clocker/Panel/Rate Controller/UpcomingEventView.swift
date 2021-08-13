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
    private var trackingArea: NSTrackingArea?

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        clickPoint = event.locationInWindow

        var gestureInProgress = true
        while gestureInProgress {
            let newEvent = window?.nextEvent(matching: [.leftMouseDragged, .leftMouseUp, .leftMouseDown])
            switch newEvent?.type {
            case .leftMouseDragged:
                let newPoint = newEvent?.locationInWindow
                let xCoOrdinate = clickPoint.x - (newPoint?.x ?? 0)
                let newOrigin = NSPoint(x: bounds.origin.x + xCoOrdinate,
                                        y: 0)
                let constrainedRect = constrainBoundsRect(NSRect(origin: newOrigin, size: bounds.size))
                scroll(to: constrainedRect.origin)
                superview?.reflectScrolledClipView(self)
            case .leftMouseDown:
                clickPoint = event.locationInWindow
            case .leftMouseUp:
                clickPoint = nil
                gestureInProgress = false
            default:
                print("Default case is happening \(event.type)")
            }
        }
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
