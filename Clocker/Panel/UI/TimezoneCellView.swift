// Copyright © 2015 Abhishek Banthia

import Cocoa
import CoreLoggerKit

class TimezoneCellView: NSTableCellView {
    @IBOutlet var customName: NSTextField!
    @IBOutlet var relativeDate: NSTextField!
    @IBOutlet var time: NSTextField!
    @IBOutlet var sunriseSetTime: NSTextField!
    @IBOutlet var noteLabel: NSTextField!
    @IBOutlet var extraOptions: NSButton!
    @IBOutlet var sunriseImage: NSImageView!
    @IBOutlet var currentLocationIndicator: NSImageView!

    private static let minimumFontSizeForTime: Int = 10
    private static let minimumFontSizeForLabel: Int = 8

    var rowNumber: NSInteger = -1
    var isPopoverDisplayed: Bool = false

    override func awakeFromNib() {
        if ProcessInfo.processInfo.arguments.contains(UserDefaultKeys.testingLaunchArgument) {
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

        if relativeDateString.length > 0 {
            if relativeDate.isHidden {
                relativeDate.isHidden = false
            }
            for constraint in relativeDate.constraints where constraint.identifier == "relative-day-height" {
                constraint.constant = 22
            }
            for constraint in relativeDate.constraints where constraint.identifier == "width" {
                constraint.constant = width + 8
            }
            for constraint in constraints where constraint.identifier == "custom-name-top-space" {
                if constraint.constant != 12 {
                    constraint.constant = 12
                }
            }
        } else {
            relativeDate.isHidden = true
            for constraint in relativeDate.constraints where constraint.identifier == "relative-day-height" {
                constraint.constant = 0
            }
            for constraint in constraints where constraint.identifier == "custom-name-top-space" {
                if constraint.constant == 12 {
                    constraint.constant += 15
                }
            }
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
        guard let userFontSize = DataStore.shared().retrieve(key: UserDefaultKeys.userFontSizePreference) as? NSNumber else {
            assertionFailure("User Font Size is in unexpected format")
            return
        }

        guard let customFont = customName.font,
              let timeFont = time.font
        else {
            assertionFailure("User Font Size is in unexpectedly nil")
            return
        }

        let newFontSize = CGFloat(TimezoneCellView.minimumFontSizeForLabel + (userFontSize.intValue * 1))
        let newTimeFontSize = CGFloat(TimezoneCellView.minimumFontSizeForTime + (userFontSize.intValue * 2))

        let fontManager = NSFontManager.shared

        customName.font = fontManager.convert(customFont, toSize: newFontSize)
        time.font = fontManager.convert(timeFont, toSize: newTimeFontSize)
    }

    @IBAction func showExtraOptions(_ sender: NSButton) {
        let isWindowFloating = DataStore.shared().shouldDisplay(ViewType.showAppInForeground)

        var searchView = superview

        while searchView != nil, searchView is PanelTableView == false {
            searchView = searchView?.superview
        }

        guard let panelTableView = searchView as? PanelTableView,
              let enclosingScroller = panelTableView.enclosingScrollView
        else {
            // We might be coming from the preview tableview!
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

        Logger.log(object: nil, for: "Open Extra Options")
    }

    func setNoteLabel(hidden: Bool) {
        noteLabel.isHidden = hidden
        for constraint in noteLabel.constraints where constraint.identifier == "note-label-height" {
            constraint.constant = hidden ? 0 : 22
        }
    }

    override func mouseDown(with event: NSEvent) {
        if event.clickCount == 1 {
            // Text is copied in the following format: Chicago - 1625185925
            let clipboardCopy = "\(customName.stringValue) - \(time.stringValue)"
            let pasteboard = NSPasteboard.general
            pasteboard.declareTypes([.string], owner: nil)
            pasteboard.setString(clipboardCopy, forType: .string)

            window?.contentView?.makeToast("Copied to Clipboard".localized())

            window?.endEditing(for: nil)
        } else if event.clickCount == 2 {
            // TODO: Favourite this timezone
        }
    }

    override func rightMouseDown(with event: NSEvent) {
        super.rightMouseDown(with: event)
        showExtraOptions(extraOptions)
        Logger.log(object: nil, for: "Right Click Open Options")
    }
}
