// Copyright © 2015 Abhishek Banthia

import CoreLoggerKit
import Foundation

extension ParentPanelController: NSCollectionViewDataSource {
    func collectionView(_: NSCollectionView, numberOfItemsInSection _: Int) -> Int {
        return (96 * PanelConstants.modernSliderDaySupport * 2) + 1
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: HourMarkerViewItem.reuseIdentifier, for: indexPath) as! HourMarkerViewItem
        item.setup(with: indexPath.item)
        return item
    }
}

extension ParentPanelController {
    func setupModernSliderIfNeccessary() {
        if modernSlider != nil {
            modernSlider.enclosingScrollView?.scrollerInsets = NSEdgeInsets(top: 0, left: 0, bottom: 10, right: 0)
            modernSlider.enclosingScrollView?.backgroundColor = NSColor.clear
            modernSlider.postsBoundsChangedNotifications = true
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(collectionViewDidScroll(_:)),
                                                   name: NSView.boundsDidChangeNotification,
                                                   object: modernSlider.superview)
            closestQuarterTimeRepresentation = setModernLabel()
            let indexPaths: Set<IndexPath> = Set([IndexPath(item: modernSlider.numberOfItems(inSection: 0) / 2, section: 0)])
            modernSlider.scrollToItems(at: indexPaths, scrollPosition: .centeredHorizontally)
        }
    }

    @IBAction func goForward(_: NSButton) {
        navigateModernSliderToSpecificIndex(1)
    }

    @IBAction func goBackward(_: NSButton) {
        navigateModernSliderToSpecificIndex(-1)
    }

    private func navigateModernSliderToSpecificIndex(_ index: Int) {
        guard let contentView = modernSlider.superview as? NSClipView else {
            return
        }
        let changedOrigin = contentView.documentVisibleRect.origin
        let newPoint = NSPoint(x: changedOrigin.x + contentView.frame.width / 2, y: changedOrigin.y)
        if let indexPath = modernSlider.indexPathForItem(at: newPoint) {
            let previousIndexPath = IndexPath(item: indexPath.item + index, section: indexPath.section)
            modernSlider.scrollToItems(at: Set([previousIndexPath]), scrollPosition: .centeredHorizontally)
        }
    }

    @objc func collectionViewDidScroll(_ notification: NSNotification) {
        guard let contentView = notification.object as? NSClipView else {
            return
        }

        let changedOrigin = contentView.documentVisibleRect.origin
        let newPoint = NSPoint(x: changedOrigin.x + contentView.frame.width / 2, y: changedOrigin.y)
        let indexPath = modernSlider.indexPathForItem(at: newPoint)
        if let correctIndexPath = indexPath?.item, currentCenterIndexPath != correctIndexPath {
            currentCenterIndexPath = correctIndexPath
            let minutesToAdd = setDefaultDateLabel(correctIndexPath)
            setTimezoneDatasourceSlider(sliderValue: minutesToAdd)
            mainTableView.reloadData()
        }
    }

    @discardableResult
    public func setModernSliderLabel(_ shouldUpdate: Bool = false) -> Date {
        let defaultParameters = minuteFromCalendar()
        let hourQuarterDate = Calendar.current.nextDate(after: defaultParameters.0,
                                                        matching: DateComponents(minute: defaultParameters.1),
                                                        matchingPolicy: .strict,
                                                        repeatedTimePolicy: .first,
                                                        direction: .forward)!

        if shouldUpdate {
            modernSliderLabel.stringValue = timezoneFormattedStringRepresentation(hourQuarterDate)
        } else {
            let fullString = NSMutableAttributedString(string: "Time Scroller")
            modernSliderLabel.attributedStringValue = fullString
        }

        return hourQuarterDate
    }

    public func setDefaultDateLabel(_ index: Int) -> Int {
        let totalCount = (96 * PanelConstants.modernSliderDaySupport * 2) + 1
        let centerPoint = Int(ceil(Double(totalCount / 2)))
        if index > (centerPoint + 1) {
            let remainder = (index % (centerPoint + 1))
            let nextDate = Calendar.current.date(byAdding: .minute, value: remainder * 15, to: closestQuarterTimeRepresentation ?? Date())!
            modernSliderLabel.stringValue = timezoneFormattedStringRepresentation(nextDate)
            return nextDate.minutes(from: Date()) + 1
        } else if index <= centerPoint {
            let remainder = centerPoint - index + 1
            let previousDate = Calendar.current.date(byAdding: .minute, value: -1 * remainder * 15, to: closestQuarterTimeRepresentation ?? Date())!
            modernSliderLabel.stringValue = timezoneFormattedStringRepresentation(previousDate)
            return previousDate.minutes(from: Date())
        } else {
            setModernSliderLabel(true)
            return 0
        }
    }

    private func minuteFromCalendar() -> (Date, Int) {
        let currentDate = Date()
        var minute = Calendar.current.component(.minute, from: currentDate)
        if minute < 15 {
            minute = 15
        } else if minute < 30 {
            minute = 30
        } else if minute < 45 {
            minute = 45
        } else {
            minute = 0
        }

        return (currentDate, minute)
    }

    private func timezoneFormattedStringRepresentation(_ date: Date) -> String {
        let dateFormatter = DateFormatterManager.dateFormatterWithFormat(with: .none,
                                                                         format: "MMM d HH:mm",
                                                                         timezoneIdentifier: TimeZone.current.identifier,
                                                                         locale: Locale.autoupdatingCurrent)
        return dateFormatter.string(from: date)
    }
}
