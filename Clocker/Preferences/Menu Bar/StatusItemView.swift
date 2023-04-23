// Copyright © 2015 Abhishek Banthia

import Cocoa
import CoreModelKit

var defaultTimeParagraphStyle: NSMutableParagraphStyle {
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = .center
    paragraphStyle.lineBreakMode = .byTruncatingTail
    return paragraphStyle
}

var defaultParagraphStyle: NSMutableParagraphStyle {
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = .center
    paragraphStyle.lineBreakMode = .byTruncatingTail
    // Better readability for p,q,y,g in the status bar.
    let userPreferredLanguage = Locale.preferredLanguages.first ?? "en-US"
    let lineHeight = userPreferredLanguage.contains("en") ? 0.92 : 1
    paragraphStyle.lineHeightMultiple = CGFloat(lineHeight)
    return paragraphStyle
}

var compactModeTimeFont: NSFont {
    return NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .regular)
}

extension NSView {
    var hasDarkAppearance: Bool {
        if #available(OSX 10.14, *) {
            switch effectiveAppearance.name {
            case .darkAqua, .vibrantDark, .accessibilityHighContrastDarkAqua, .accessibilityHighContrastVibrantDark:
                return true
            default:
                return false
            }
        } else {
            switch effectiveAppearance.name {
            case .vibrantDark:
                return true
            default:
                return false
            }
        }
    }
}

class StatusItemView: NSView {
    // MARK: Private variables

    private let locationView = NSTextField(labelWithString: "Hello")
    private let timeView = NSTextField(labelWithString: "Mon 19:14 PM")
    private var operationsObject: TimezoneDataOperations {
        return TimezoneDataOperations(with: dataObject, store: DataStore.shared())
    }

    private var timeAttributes: [NSAttributedString.Key: AnyObject] {
        let textColor = hasDarkAppearance ? NSColor.white : NSColor.black

        let attributes = [
            NSAttributedString.Key.font: compactModeTimeFont,
            NSAttributedString.Key.foregroundColor: textColor,
            NSAttributedString.Key.backgroundColor: NSColor.clear,
            NSAttributedString.Key.paragraphStyle: defaultTimeParagraphStyle,
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

    // MARK: Public

    var dataObject: TimezoneData! {
        didSet {
            initialSetup()
        }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        [timeView, locationView].forEach {
            $0.wantsLayer = true
            $0.applyDefaultStyle()
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        timeView.disableWrapping()

        NSLayoutConstraint.activate([
            locationView.leadingAnchor.constraint(equalTo: leadingAnchor),
            locationView.trailingAnchor.constraint(equalTo: trailingAnchor),
            locationView.topAnchor.constraint(equalTo: topAnchor, constant: 7),
            locationView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.35),
        ])

        NSLayoutConstraint.activate([
            timeView.leadingAnchor.constraint(equalTo: leadingAnchor),
            timeView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
            timeView.topAnchor.constraint(equalTo: locationView.bottomAnchor),
            timeView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    @available(OSX 10.14, *)
    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        statusItemViewSetNeedsDisplay()
    }

    private func initialSetup() {
        locationView.attributedStringValue = NSAttributedString(string: operationsObject.compactMenuTitle(), attributes: textFontAttributes)
        timeView.attributedStringValue = NSAttributedString(string: operationsObject.compactMenuSubtitle(), attributes: timeAttributes)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        guard let mainDelegate = NSApplication.shared.delegate as? AppDelegate else {
            return
        }

        mainDelegate.togglePanel(event)
    }
}

extension StatusItemView: StatusItemViewConforming {
    func statusItemViewSetNeedsDisplay() {
        locationView.attributedStringValue = NSAttributedString(string: operationsObject.compactMenuTitle(), attributes: textFontAttributes)
        timeView.attributedStringValue = NSAttributedString(string: operationsObject.compactMenuSubtitle(), attributes: timeAttributes)
    }

    func statusItemViewIdentifier() -> String {
        return "location_view"
    }
}
