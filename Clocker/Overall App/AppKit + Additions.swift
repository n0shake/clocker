// Copyright © 2015 Abhishek Banthia

extension NSTextField {
    func applyDefaultStyle() {
        backgroundColor = NSColor.clear
        isEditable = false
        isBordered = false
        allowsDefaultTighteningForTruncation = true

        if #available(OSX 10.12.2, *) {
            isAutomaticTextCompletionEnabled = false
            allowsCharacterPickerTouchBarItem = false
        }
    }

    func disableWrapping() {
        usesSingleLineMode = false
        cell?.wraps = false
        cell?.isScrollable = true
    }
}

extension NSFont {
    func size(for string: String, width: Double, attributes: [NSAttributedString.Key: AnyObject]) -> CGSize {
        let size = CGSize(width: width,
                          height: Double.greatestFiniteMagnitude)

        var otherAttributes: [NSAttributedString.Key: AnyObject] = [NSAttributedString.Key.font: self]

        attributes.forEach { arg in let (key, value) = arg; otherAttributes[key] = value }

        return NSString(string: string).boundingRect(with: size,
                                                     options: NSString.DrawingOptions.usesLineFragmentOrigin,
                                                     attributes: attributes).size
    }
}
