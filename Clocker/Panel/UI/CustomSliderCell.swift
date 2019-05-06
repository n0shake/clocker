// Copyright © 2015 Abhishek Banthia

import Cocoa

class CustomSliderCell: NSSliderCell {
    fileprivate(set) var tracking: Bool = false

    override func drawBar(inside rect: NSRect, flipped _: Bool) {
        let barRadius: CGFloat = 2.5

        let value = CGFloat((doubleValue - minValue) / (maxValue - minValue))

        guard let control = controlView else {
            return
        }

        let finalWidth = value * (control.frame.width - 8)

        // Left Part
        var leftRect = rect
        leftRect.size.width = finalWidth

        let background = NSBezierPath(roundedRect: rect,
                                      xRadius: barRadius,
                                      yRadius: barRadius)
        NSColor(calibratedRed: 67.0 / 255.0, green: 138.0 / 255.0, blue: 250.0 / 255.0, alpha: 1.0).setFill()

        background.fill()

        // Right Part

        let active = NSBezierPath(roundedRect: leftRect,
                                  xRadius: barRadius,
                                  yRadius: barRadius)

        Themer.shared().sliderRightColor().setFill()
        active.fill()
    }

    override func startTracking(at startPoint: NSPoint, in controlView: NSView) -> Bool {
        tracking = true
        return super.startTracking(at: startPoint, in: controlView)
    }

    override func stopTracking(last lastPoint: NSPoint, current stopPoint: NSPoint, in controlView: NSView, mouseIsUp flag: Bool) {
        super.stopTracking(last: lastPoint, current: stopPoint, in: controlView, mouseIsUp: flag)
        tracking = false
    }
}
