// Copyright © 2015 Abhishek Banthia

import Cocoa

struct BackgroundPanelConstants {
    static let kArrowHeight: CGFloat = 8
    static let kCornerRadius: CGFloat = 8
    static let kBorderWidth: CGFloat = 1
}

class BackgroundPanelView: NSView {
    private var arrowX: CGFloat = -1
    private var trackingArea: NSTrackingArea?

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        NSColor.clear.set()
        bounds.fill(using: .copy)

        var rect = bounds.insetBy(dx: 1, dy: 0)
        rect.origin.y = BackgroundPanelConstants.kBorderWidth
        rect.size.height -= (BackgroundPanelConstants.kArrowHeight + (2 * BackgroundPanelConstants.kBorderWidth))

        let rectPath = NSBezierPath(roundedRect: rect,
                                    xRadius: BackgroundPanelConstants.kCornerRadius,
                                    yRadius: BackgroundPanelConstants.kCornerRadius)

        // Append the arrow to the body if its right ege is inside
        // the right edge of the body (taking into account the corner
        // radius).

        let curveOffset: CGFloat = 5
        let arrowMidX = frame.midX
        let arrowRightEdge = arrowMidX + curveOffset + BackgroundPanelConstants.kArrowHeight
        let bodyRightEdge = rect.maxX - BackgroundPanelConstants.kCornerRadius

        if arrowRightEdge < bodyRightEdge {
            let arrowPath = NSBezierPath()
            let xOrdinate = arrowMidX - BackgroundPanelConstants.kArrowHeight - curveOffset
            let yOrdinate = frame.height - BackgroundPanelConstants.kArrowHeight - BackgroundPanelConstants.kBorderWidth
            arrowPath.move(to: NSPoint(x: xOrdinate, y: yOrdinate))
            arrowPath.relativeCurve(to: NSPoint(x: BackgroundPanelConstants.kArrowHeight + curveOffset,
                                                y: BackgroundPanelConstants.kBorderWidth),
                                    controlPoint1: NSPoint(x: curveOffset, y: 0),
                                    controlPoint2: NSPoint(x: BackgroundPanelConstants.kArrowHeight, y: BackgroundPanelConstants.kArrowHeight))
        }

        Themer.shared().mainBackgroundColor().setFill()

        rectPath.lineWidth = 2 * BackgroundPanelConstants.kBorderWidth
        rectPath.stroke()
        rectPath.fill()
    }

    override var allowsVibrancy: Bool {
        return true
    }

    func setArrowX(value: CGFloat) {
        arrowX = value
        setNeedsDisplay(bounds)
    }
}
