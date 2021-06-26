// Copyright © 2015 Abhishek Banthia

import Cocoa

class HourMarkerViewItem: NSCollectionViewItem {
    static let reuseIdentifier = NSUserInterfaceItemIdentifier("HourMarkerViewItem")
    public var timeRepresentation: String = "-1"

    func setup(with index: Int, value: String) {
        timeRepresentation = value

        for constraint in view.constraints where constraint.identifier == "constrainFromTop" {
            if index % 4 == 0 {
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
