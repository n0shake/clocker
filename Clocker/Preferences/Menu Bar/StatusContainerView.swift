// Copyright © 2015 Abhishek Banthia

import Cocoa
import CoreLoggerKit
import CoreModelKit

func compactWidth(for timezone: TimezoneData, with store: DataStore) -> Int {
    var totalWidth = 55
    let timeFormat = timezone.timezoneFormat(store.timezoneFormat())

    if store.shouldShowDayInMenubar() {
        totalWidth += 12
    }

    if timeFormat == DateFormat.twelveHour
        || timeFormat == DateFormat.twelveHourWithSeconds
        || timeFormat == DateFormat.twelveHourWithZero
        || timeFormat == DateFormat.twelveHourWithSeconds
    {
        totalWidth += 20
    } else if timeFormat == DateFormat.twentyFourHour
        || timeFormat == DateFormat.twentyFourHourWithSeconds
    {
        totalWidth += 0
    }

    if timezone.shouldShowSeconds(store.timezoneFormat()) {
        // Slight buffer needed when the Menubar supplementary text was Mon 9:27:58 AM
        totalWidth += 15
    }

    if store.shouldShowDateInMenubar() {
        totalWidth += 20
    }

    return totalWidth
}

// Test with Sat 12:46 AM
let bufferWidth: CGFloat = 9.5
let upcomingEventBufferWidth: CGFloat = 32.5

protocol StatusItemViewConforming {
    /// Mark that we need to refresh the text we're showing in the menubar
    func statusItemViewSetNeedsDisplay()

    /// Status Item Views can be used to represent different information (like time in location, or an upcoming meeting). Distinguish between different status items view through this identifier
    func statusItemViewIdentifier() -> String
}

/// Observe for User Default changes for timezones in App Delegate and reconstruct the Status View if neccesary
/// We'll inject the menubar timezones into Status Container View which'll pass it to StatusItemView
/// The benefit of doing so is reducing time-spent calculating menubar timezones and deserialization through `TimezoneData.customObject`
///  Also inject, `shouldDisplaySecondsInMenubar`
///

class StatusContainerView: NSView {
    private var previousX: Int = 0
    private let store: DataStore

    override func awakeFromNib() {
        super.awakeFromNib()
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    init(with timezones: [Data],
         store: DataStore,
         showUpcomingEventView: Bool,
         bufferContainerWidth: Int)
    {
        self.store = store

        func addSubviews() {
            if showUpcomingEventView,
               let events = EventCenter.sharedCenter().eventsForDate[NSCalendar.autoupdatingCurrent.startOfDay(for: Date())],
               events.isEmpty == false,
               let upcomingEvent = EventCenter.sharedCenter().nextOccuring(events)
            {
                let calculatedWidth = bestWidth(for: upcomingEvent)
                let frame = NSRect(x: previousX, y: 0, width: calculatedWidth, height: 30)
                let calendarItemView = UpcomingEventStatusItemView(frame: frame)
                calendarItemView.dataObject = upcomingEvent
                addSubview(calendarItemView)
                previousX += calculatedWidth
            }

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

        func containerWidth(for timezones: [Data], event: EventInfo?) -> CGFloat {
            var compressedWidth = timezones.reduce(0.0) { result, timezone -> CGFloat in

                if let timezoneObject = TimezoneData.customObject(from: timezone) {
                    let precalculatedWidth = Double(compactWidth(for: timezoneObject, with: store))
                    let operationObject = TimezoneDataOperations(with: timezoneObject, store: store)
                    let calculatedSubtitleSize = compactModeTimeFont.size(for: operationObject.compactMenuSubtitle(),
                                                                          width: precalculatedWidth,
                                                                          attributes: timeBasedAttributes)
                    let calculatedTitleSize = compactModeTimeFont.size(for: operationObject.compactMenuTitle(),
                                                                       width: precalculatedWidth,
                                                                       attributes: timeBasedAttributes)
                    let showSeconds = timezoneObject.shouldShowSeconds(store.timezoneFormat())
                    let secondsBuffer: CGFloat = showSeconds ? 7 : 0
                    return result + max(calculatedTitleSize.width, calculatedSubtitleSize.width) + bufferWidth + secondsBuffer
                }

                return result + CGFloat(bufferContainerWidth)
            }

            if showUpcomingEventView {
                let calculateMeetingHeaderSize = compactModeTimeFont.size(for: upcomingEvent?.event.title ?? "", width: 70, attributes: timeBasedAttributes)
                let calculatedMeetingSubtitleSize = compactModeTimeFont.size(for: upcomingEvent?.metadataForMeeting() ?? "", width: 55, attributes: timeBasedAttributes)
                compressedWidth += CGFloat(min(calculateMeetingHeaderSize.width, calculatedMeetingSubtitleSize.width) + bufferWidth + upcomingEventBufferWidth)
            }

            let calculatedWidth = min(compressedWidth,
                                      CGFloat(timezones.count * bufferContainerWidth))
            return calculatedWidth
        }

        let events = EventCenter.sharedCenter().eventsForDate[NSCalendar.autoupdatingCurrent.startOfDay(for: Date())]
        let upcomingEvent = EventCenter.sharedCenter().nextOccuring(events ?? [])

        let statusItemWidth = containerWidth(for: timezones, event: upcomingEvent)
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

        let operation = TimezoneDataOperations(with: timezone, store: store)
        let bestSize = compactModeTimeFont.size(for: operation.compactMenuSubtitle(),
                                                width: Double(compactWidth(for: timezone, with: store)),
                                                attributes: timeBasedAttributes)
        let bestTitleSize = compactModeTimeFont.size(for: operation.compactMenuTitle(),
                                                     width: Double(compactWidth(for: timezone, with: store)),
                                                     attributes: timeBasedAttributes)

        return Int(max(bestSize.width, bestTitleSize.width) + bufferWidth)
    }

    private func bestWidth(for eventInfo: EventInfo) -> Int {
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

        let bestSize = compactModeTimeFont.size(for: eventInfo.metadataForMeeting(),
                                                width: 55, // Default for a location based status view
                                                attributes: timeBasedAttributes)
        let bestTitleSize = compactModeTimeFont.size(for: eventInfo.event.title,
                                                     width: 70, // Little more buffer since meeting titles tend to be longer
                                                     attributes: timeBasedAttributes)

        return Int(max(bestSize.width, bestTitleSize.width) + bufferWidth)
    }

    func updateTime() {
        if subviews.isEmpty {
            assertionFailure("Subviews count should > 0")
        }

        for view in subviews {
            if let conformingView = view as? StatusItemViewConforming {
                conformingView.statusItemViewSetNeedsDisplay()
            }
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
            } else if let upcomingEventView = $0 as? UpcomingEventStatusItemView, upcomingEventView.isHidden == false {
                let newBestWidth = CGFloat(bestWidth(for: upcomingEventView.dataObject))

                // Let's note if the current width is too small/correct
                newWidth += $0.frame.size.width != newBestWidth ? newBestWidth : upcomingEventView.frame.size.width

                upcomingEventView.frame = CGRect(x: upcomingEventView.frame.origin.x,
                                          y: upcomingEventView.frame.origin.y,
                                          width: newBestWidth,
                                          height: upcomingEventView.frame.size.height)
            }
        }

        if newWidth != frame.size.width, newWidth > frame.size.width + 2.0 {
            Logger.info("Correcting our width to \(newWidth) and the previous width was \(frame.size.width)")
            // NSView move animation
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.2
                context.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
                let newFrame = CGRect(x: frame.origin.x, y: frame.origin.y, width: newWidth, height: frame.size.height)
                // The view will animate to the new origin
                self.animator().frame = newFrame
            }) {}
        }
    }
}
