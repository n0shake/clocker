// Copyright © 2015 Abhishek Banthia

import Cocoa
import QuartzCore

class NoTimezoneView: NSView {
    private lazy var emoji: NSTextField = {
        let l = NSTextField(frame: NSRect(x: frame.size.width / 2 - 50,
                                          y: frame.size.height / 2 - 50,
                                          width: 100,
                                          height: 100))
        l.wantsLayer = true
        l.stringValue = "🌏"
        l.isBordered = false
        l.isEditable = false
        l.focusRingType = .none
        l.alignment = .center
        l.font = NSFont.systemFont(ofSize: 80)
        l.backgroundColor = .clear
        l.setAccessibilityIdentifier("NoTimezoneEmoji")
        return l
    }()

    private lazy var message: NSTextField = {
        let m = NSTextField(frame: NSRect(x: frame.size.width / 2 - 250,
                                          y: frame.size.height / 2 - 275,
                                          width: 500,
                                          height: 200))
        m.wantsLayer = true
        m.setAccessibilityIdentifier("NoTimezoneMessage")
        m.placeholderString = "No places added"
        m.stringValue = "No places added"
        m.isBordered = false
        m.isEditable = false
        m.maximumNumberOfLines = 2
        m.focusRingType = .none
        m.alignment = .center
        m.font = NSFont(name: "Avenir", size: 24)
        m.backgroundColor = .clear
        m.textColor = .darkGray
        return m
    }()

    override func layout() {
        if !subviews.contains(emoji) {
            addSubview(emoji)
            addSubview(message)
        }

        resetAnimations()

        super.layout()
    }

    private func resetAnimations() {
        let function = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)

        let emojiAnimation = CABasicAnimation(keyPath: "transform.translation.y")
        emojiAnimation.toValue = -10
        emojiAnimation.repeatCount = .greatestFiniteMagnitude
        emojiAnimation.autoreverses = true
        emojiAnimation.duration = 1
        emojiAnimation.timingFunction = function

        emoji.layer?.removeAllAnimations()
        emoji.layer?.add(emojiAnimation, forKey: "notimezone.emoji")

        let shadowScale = CABasicAnimation(keyPath: "transform.scale")
        shadowScale.toValue = 0.9
        shadowScale.repeatCount = .greatestFiniteMagnitude
        shadowScale.autoreverses = true
        shadowScale.duration = 1
        shadowScale.timingFunction = function
    }
}
