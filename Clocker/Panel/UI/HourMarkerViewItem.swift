// Copyright © 2015 Abhishek Banthia

import Cocoa

class HourMarkerViewItem: NSCollectionViewItem {
    static let reuseIdentifier = NSUserInterfaceItemIdentifier("HourMarkerViewItem")

    @IBOutlet var constraintFromTop: NSLayoutConstraint!
    @IBOutlet var verticalLine: NSBox!

    public var indexTag: Int = -1

    func setup(with hour: Int) {
        var dateComponents = DateComponents()
        dateComponents.minute = hour * 15
        indexTag = hour

        for constraint in view.constraints where constraint.identifier == "constrainFromTop" {
            if hour % 4 == 0 {
                constraint.constant = 0
            } else {
                constraint.constant = 20
            }
        }
    }

    func setupLineColor() {
        for subview in view.subviews where subview is NSBox {
            subview.layer?.backgroundColor = NSColor.black.cgColor
        }
    }

    func resetLineColor() {
        for subview in view.subviews where subview is NSBox {
            subview.layer?.backgroundColor = nil
        }
    }

    override var acceptsFirstResponder: Bool {
        return false
    }
}

extension Date {
    public var nextHour: Date {
        let calendar = Calendar.current
        let minutes = calendar.component(.minute, from: self)
        let components = DateComponents(hour: 1, minute: -minutes)
        return calendar.date(byAdding: components, to: self) ?? self
    }
}
