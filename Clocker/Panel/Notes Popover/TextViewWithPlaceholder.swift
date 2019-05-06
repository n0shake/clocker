// Copyright © 2015 Abhishek Banthia

import AppKit
import Cocoa

class TextViewWithPlaceholder: NSTextView {
    let placeholder = makePlaceHolder()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    class func makePlaceHolder() -> NSAttributedString {
        if let placeHolderFont = NSFont(name: "Avenir", size: 14) {
            let textDict = [
                NSAttributedString.Key.foregroundColor: NSColor.gray,
                NSAttributedString.Key.font: placeHolderFont,
            ]
            return NSAttributedString(string: " Add your notes here.", attributes: textDict)
        }
        return NSAttributedString(string: " Add your notes here")
    }

    override func becomeFirstResponder() -> Bool {
        setNeedsDisplay(frame)
        return super.becomeFirstResponder()
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        if string == CLEmptyString, self != window?.firstResponder {
            placeholder.draw(at: NSPoint(x: 0, y: 0))
        }
    }

    override func resignFirstResponder() -> Bool {
        setNeedsDisplay(frame)
        return super.resignFirstResponder()
    }
}
