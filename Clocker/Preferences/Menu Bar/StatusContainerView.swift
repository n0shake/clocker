// Copyright © 2015 Abhishek Banthia

import Cocoa
import CoreLoggerKit
import CoreModelKit

func bufferCalculatedWidth() -> Int {
    var totalWidth = 55

    if DataStore.shared().shouldShowDayInMenubar() {
        totalWidth += 12
    }

    if DataStore.shared().isBufferRequiredForTwelveHourFormats() {
        totalWidth += 20
    }

    if DataStore.shared().shouldShowDateInMenubar() {
        totalWidth += 20
    }

    return totalWidth
}

func compactWidth(for timezone: TimezoneData) -> Int {
    var totalWidth = 55
    let timeFormat = timezone.timezoneFormat(DataStore.shared().timezoneFormat())

    if DataStore.shared().shouldShowDayInMenubar() {
        totalWidth += 12
    }

    if timeFormat == DateFormat.twelveHour
        || timeFormat == DateFormat.twelveHourWithSeconds
        || timeFormat == DateFormat.twelveHourWithZero
        || timeFormat == DateFormat.twelveHourWithSeconds {
        totalWidth += 20
    } else if timeFormat == DateFormat.twentyFourHour
        || timeFormat == DateFormat.twentyFourHourWithSeconds {
        totalWidth += 0
    }

    if timezone.shouldShowSeconds(DataStore.shared().timezoneFormat()) {
        // Slight buffer needed when the Menubar supplementary text was Mon 9:27:58 AM
        totalWidth += 15
    }

    if DataStore.shared().shouldShowDateInMenubar() {
        totalWidth += 20
    }

    return totalWidth
}

// Test with Sat 12:46 AM
let bufferWidth: CGFloat = 9.5

class StatusContainerView: NSView {
    private var previousX: Int = 0

    override func awakeFromNib() {
        super.awakeFromNib()
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    init(with timezones: [Data]) {
        func addSubviews() {
            timezones.forEach {
                if let timezoneObject = TimezoneData.customObject(from: $0) {
                    addTimezone(timezoneObject)
                }
            }
        }

        let timeBasedAttributes = [
            NSAttributedString.Key.font: compactModeTimeFont,
            NSAttributedString.Key.backgroundColor: NSColor.clear,
            NSAttributedString.Key.paragraphStyle: defaultParagraphStyle,
        ]

        func containerWidth(for timezones: [Data]) -> CGFloat {
            let compressedWidth = timezones.reduce(0.0) { result, timezone -> CGFloat in

                if let timezoneObject = TimezoneData.customObject(from: timezone) {
                    let precalculatedWidth = Double(compactWidth(for: timezoneObject))
                    let operationObject = TimezoneDataOperations(with: timezoneObject)
                    let calculatedSubtitleSize = compactModeTimeFont.size(operationObject.compactMenuSubtitle(), precalculatedWidth, attributes: timeBasedAttributes)
                    let calculatedTitleSize = compactModeTimeFont.size(operationObject.compactMenuTitle(), precalculatedWidth, attributes: timeBasedAttributes)
                    let showSeconds = timezoneObject.shouldShowSeconds(DataStore.shared().timezoneFormat())
                    let secondsBuffer: CGFloat = showSeconds ? 7 : 0
                    return result + max(calculatedTitleSize.width, calculatedSubtitleSize.width) + bufferWidth + secondsBuffer
                }

                return result + CGFloat(bufferCalculatedWidth())
            }

            let calculatedWidth = min(compressedWidth,
                                      CGFloat(timezones.count * bufferCalculatedWidth()))
            return calculatedWidth
        }

        let statusItemWidth = containerWidth(for: timezones)
        let frame = NSRect(x: 0, y: 0, width: statusItemWidth, height: 30)
        super.init(frame: frame)

        addSubviews()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func addTimezone(_ timezone: TimezoneData) {
        let calculatedWidth = bestWidth(for: timezone)
        let frame = NSRect(x: previousX, y: 0, width: calculatedWidth, height: 30)

        let statusItemView = StatusItemView(frame: frame)
        statusItemView.dataObject = timezone

        addSubview(statusItemView)

        previousX += calculatedWidth
    }

    private func bestWidth(for timezone: TimezoneData) -> Int {
        var textColor = hasDarkAppearance ? NSColor.white : NSColor.black

        if #available(OSX 11.0, *) {
            textColor = NSColor.white
        }

        let timeBasedAttributes = [
            NSAttributedString.Key.font: compactModeTimeFont,
            NSAttributedString.Key.foregroundColor: textColor,
            NSAttributedString.Key.backgroundColor: NSColor.clear,
            NSAttributedString.Key.paragraphStyle: defaultParagraphStyle,
        ]

        let operation = TimezoneDataOperations(with: timezone)
        let bestSize = compactModeTimeFont.size(operation.compactMenuSubtitle(),
                                                Double(compactWidth(for: timezone)), attributes: timeBasedAttributes)
        let bestTitleSize = compactModeTimeFont.size(operation.compactMenuTitle(), Double(compactWidth(for: timezone)), attributes: timeBasedAttributes)

        return Int(max(bestSize.width, bestTitleSize.width) + bufferWidth)
    }

    func updateTime() {
        if subviews.isEmpty {
            assertionFailure("Subviews count should > 0")
        }

        // See if frame's width needs any adjustment
        adjustWidthIfNeccessary()
    }

    private func adjustWidthIfNeccessary() {
        var newWidth: CGFloat = 0

        subviews.forEach {
            if let statusItem = $0 as? StatusItemView, statusItem.isHidden == false {
                // Determine what's the best width required to display the current string.
                let newBestWidth = CGFloat(bestWidth(for: statusItem.dataObject))

                // Let's note if the current width is too small/correct
                newWidth += statusItem.frame.size.width != newBestWidth ? newBestWidth : statusItem.frame.size.width

                statusItem.frame = CGRect(x: statusItem.frame.origin.x,
                                          y: statusItem.frame.origin.y,
                                          width: newBestWidth,
                                          height: statusItem.frame.size.height)

                statusItem.updateTimeInMenubar()
            }
        }

        if newWidth != frame.size.width, newWidth > frame.size.width + 2.0 {
            Logger.info("Correcting our width to \(newWidth) and the previous width was \(frame.size.width)")
            // NSView move animation
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.2
                let newFrame = CGRect(x: frame.origin.x, y: frame.origin.y, width: newWidth, height: frame.size.height)
                // The view will animate to the new origin
                self.animator().frame = newFrame
            }) {}
        }
    }
}
