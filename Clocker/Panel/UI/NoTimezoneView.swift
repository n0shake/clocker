// Copyright © 2015 Abhishek Banthia

import Cocoa
import QuartzCore

class NoTimezoneView: NSView {
    private lazy var emoji: NSTextField = {
        let emoji = NSTextField(frame: NSRect(x: frame.size.width / 2 - 50,
                                              y: frame.size.height / 2 - 50,
                                              width: 100,
                                              height: 100))
        emoji.wantsLayer = true
        emoji.stringValue = "🌏"
        emoji.isBordered = false
        emoji.isEditable = false
        emoji.focusRingType = .none
        emoji.alignment = .center
        emoji.font = NSFont.systemFont(ofSize: 80)
        emoji.backgroundColor = .clear
        emoji.setAccessibilityIdentifier("NoTimezoneEmoji")
        return emoji
    }()

    private lazy var message: NSTextField = {
        let messageField = NSTextField(frame: NSRect(x: frame.size.width / 2 - 250,
                                                     y: frame.size.height / 2 - 275,
                                                     width: 500,
                                                     height: 200))
        messageField.wantsLayer = true
        messageField.setAccessibilityIdentifier("NoTimezoneMessage")
        messageField.placeholderString = NSLocalizedString("No places added",
                                                           comment: "Subtitle for no places added")
        messageField.stringValue = NSLocalizedString("No places added",
                                                     comment: "Subtitle for no places added")
        messageField.isBordered = false
        messageField.isEditable = false
        messageField.maximumNumberOfLines = 2
        messageField.focusRingType = .none
        messageField.alignment = .center
        messageField.font = NSFont(name: "Avenir", size: 24)
        messageField.backgroundColor = .clear
        messageField.textColor = .darkGray
        return messageField
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
