// Copyright © 2015 Abhishek Banthia

import Cocoa

class TimezoneCellView: NSTableCellView {
    @IBOutlet var customName: NSTextField!
    @IBOutlet var relativeDate: NSTextField!
    @IBOutlet var time: NSTextField!
    @IBOutlet var sunriseSetTime: NSTextField!
    @IBOutlet var noteLabel: NSTextField!
    @IBOutlet var extraOptions: NSButton!
    @IBOutlet var sunriseImage: NSImageView!
    @IBOutlet var currentLocationIndicator: NSImageView!

    var rowNumber: NSInteger = -1
    var isPopoverDisplayed: Bool = false

    override func awakeFromNib() {
        if ProcessInfo.processInfo.arguments.contains(CLUITestingLaunchArgument) {
            extraOptions.isHidden = false
            return
        }

        sunriseSetTime.alignment = .right

        canDrawSubviewsIntoLayer = true

        extraOptions.setAccessibility("extraOptionButton")
        customName.setAccessibility("CustomNameLabelForCell")
        noteLabel.setAccessibility("NoteLabel")
        currentLocationIndicator.toolTip = "This row will be updated automatically if Clocker detects a system-level timezone change!"
    }

    func setTextColor(color: NSColor) {
        [relativeDate, customName, time, sunriseSetTime].forEach { $0?.textColor = color }
        noteLabel.textColor = .gray
    }

    func setupLayout() {
        guard let relativeFont = relativeDate.font,
            let sunriseFont = sunriseSetTime.font
        else {
            assertionFailure("Unable to convert to NSString")
            return
        }

        let relativeDateString = relativeDate.stringValue as NSString
        let sunriseString = sunriseSetTime.stringValue as NSString

        let width = relativeDateString.size(withAttributes: [NSAttributedString.Key.font: relativeFont]).width
        let sunriseWidth = sunriseString.size(withAttributes: [NSAttributedString.Key.font: sunriseFont]).width

        for constraint in relativeDate.constraints where constraint.identifier == "width" {
            constraint.constant = width + 8
        }

        for constraint in sunriseSetTime.constraints where constraint.identifier == "width" {
            constraint.constant = sunriseWidth + 3
        }

        setupTheme()
    }

    private func setupTheme() {
        let themer = Themer.shared()

        setTextColor(color: themer.mainTextColor())

        extraOptions.image = themer.extraOptionsImage()
        extraOptions.alternateImage = themer.extraOptionsHighlightedImage()

        currentLocationIndicator.image = themer.currentLocationImage()

        setupTextSize()
    }

    private func setupTextSize() {
        guard let userFontSize = DataStore.shared().retrieve(key: CLUserFontSizePreference) as? NSNumber else {
            assertionFailure("User Font Size is in unexpected format")
            return
        }

        guard let customFont = customName.font,
            let timeFont = time.font else {
            assertionFailure("User Font Size is in unexpectedly nil")
            return
        }

        let newFontSize = CGFloat(13 + (userFontSize.intValue * 2))
        let newTimeFontSize = CGFloat(13 + (userFontSize.intValue * 3))

        let fontManager = NSFontManager.shared

        let customPlaceFont = fontManager.convert(customFont, toSize: newFontSize)
        let customTimeFont = fontManager.convert(timeFont, toSize: newTimeFontSize)

        customName.font = customPlaceFont
        time.font = customTimeFont

        let timeString = time.stringValue as NSString

        let timeHeight = timeString.size(withAttributes: [NSAttributedString.Key.font: customTimeFont]).height
        let timeWidth = timeString.size(withAttributes: [NSAttributedString.Key.font: customTimeFont]).width

        for constraint in time.constraints {
            if constraint.identifier == "height" {
                constraint.constant = timeHeight
            } else {
                constraint.constant = timeWidth
            }
        }
    }

    @IBAction func showExtraOptions(_ sender: NSButton) {
        let isWindowFloating = DataStore.shared().shouldDisplay(ViewType.showAppInForeground)

        var searchView = superview

        while searchView != nil && searchView is PanelTableView == false {
            searchView = searchView?.superview
        }

        guard let panelTableView = searchView as? PanelTableView,
            let enclosingScroller = panelTableView.enclosingScrollView
        else {
            assertionFailure("Unable to find panel table view in hierarchy")
            return
        }

        let visibleRect = enclosingScroller.contentView.visibleRect
        let range = panelTableView.rows(in: visibleRect)

        let count = range.length
        let currentRow = labs(rowNumber + 1 - count)
        let yCoordinate = CGFloat(currentRow * 68 + 34)

        let relativeRect = CGRect(x: 0,
                                  y: yCoordinate,
                                  width: frame.size.width,
                                  height: frame.size.height)

        if isWindowFloating == false {
            guard let panel = PanelController.panel() else { return }
            isPopoverDisplayed = panel.showNotesPopover(forRow: rowNumber,
                                                        relativeTo: bounds,
                                                        andButton: sender)
        } else {
            let floatingPanel = FloatingWindowController.shared()
            isPopoverDisplayed = floatingPanel.showNotesPopover(forRow: rowNumber,
                                                                relativeTo: superview?.convert(bounds, to: nil) ?? relativeRect,
                                                                andButton: sender)
        }

        Logger.log(object: [:], for: "Open Extra Options")
    }

    override func mouseDown(with _: NSEvent) {
        window?.endEditing(for: nil)
    }

    override func rightMouseDown(with event: NSEvent) {
        super.rightMouseDown(with: event)
        showExtraOptions(extraOptions)
        Logger.log(object: [:], for: "Right Click Open Options")
    }
}
