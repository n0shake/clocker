// Copyright © 2015 Abhishek Banthia

import AppKit
import Foundation

class UpcomingEventStatusItemView: NSView {
    static let containerWidth = 70

    private let nextEventField = NSTextField(labelWithString: "Next Event")
    private let etaField = NSTextField(labelWithString: "5 mins")
    var dataObject: EventInfo! {
        didSet {
            initialSetup()
        }
    }

    private var timeAttributes: [NSAttributedString.Key: AnyObject] {
        let textColor = hasDarkAppearance ? NSColor.white : NSColor.black

        let attributes = [
            NSAttributedString.Key.font: compactModeTimeFont,
            NSAttributedString.Key.foregroundColor: textColor,
            NSAttributedString.Key.backgroundColor: NSColor.clear,
            NSAttributedString.Key.paragraphStyle: defaultParagraphStyle,
        ]
        return attributes
    }

    private var textFontAttributes: [NSAttributedString.Key: Any] {
        let textColor = hasDarkAppearance ? NSColor.white : NSColor.black

        let textFontAttributes = [
            NSAttributedString.Key.font: NSFont.boldSystemFont(ofSize: 10),
            NSAttributedString.Key.foregroundColor: textColor,
            NSAttributedString.Key.backgroundColor: NSColor.clear,
            NSAttributedString.Key.paragraphStyle: defaultParagraphStyle,
        ]
        return textFontAttributes
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        [etaField, nextEventField].forEach {
            $0.wantsLayer = true
            $0.applyDefaultStyle()
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        etaField.disableWrapping()

        NSLayoutConstraint.activate([
            nextEventField.leadingAnchor.constraint(equalTo: leadingAnchor),
            nextEventField.trailingAnchor.constraint(equalTo: trailingAnchor),
            nextEventField.topAnchor.constraint(equalTo: topAnchor, constant: 7),
            nextEventField.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.35),
        ])

        NSLayoutConstraint.activate([
            etaField.leadingAnchor.constraint(equalTo: leadingAnchor),
            etaField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
            etaField.topAnchor.constraint(equalTo: nextEventField.bottomAnchor),
            etaField.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func initialSetup() {
        nextEventField.attributedStringValue = NSAttributedString(string: "Next Event", attributes: textFontAttributes)
        etaField.attributedStringValue = NSAttributedString(string: dataObject.metadataForMeeting(), attributes: timeAttributes)
    }

    func updateWithNextEventInfo(_ metadata: String) {
        nextEventField.attributedStringValue = NSAttributedString(string: "Next Event", attributes: textFontAttributes)
        etaField.attributedStringValue = NSAttributedString(string: metadata, attributes: timeAttributes)
    }

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        guard let mainDelegate = NSApplication.shared.delegate as? AppDelegate else {
            return
        }

        mainDelegate.togglePanel(event)
    }
}
