// Copyright © 2015 Abhishek Banthia

import CoreLoggerKit
import Foundation

extension ParentPanelController: NSCollectionViewDataSource {
    func collectionView(_: NSCollectionView, numberOfItemsInSection _: Int) -> Int {
        return (PanelConstants.modernSliderPointsInADay * PanelConstants.modernSliderDaySupport * 2) + 1
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: TimeMarkerViewItem.reuseIdentifier, for: indexPath) as! TimeMarkerViewItem
        item.setup(with: indexPath.item)
        return item
    }
}

extension ParentPanelController {
    func setupModernSliderIfNeccessary() {
        if modernSlider != nil {
            goBackwardsButton.image = Themer.shared().goBackwardsImage()
            goForwardButton.image = Themer.shared().goForwardsImage()
            
            goForwardButton.isContinuous = true
            goBackwardsButton.isContinuous = true
            
            goBackwardsButton.toolTip = "Navigate 15 mins back"
            goForwardButton.toolTip = "Navigate 15 mins forward"
            
            modernSlider.enclosingScrollView?.scrollerInsets = NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            modernSlider.enclosingScrollView?.backgroundColor = NSColor.clear
            modernSlider.setAccessibility("ModernSlider")
            modernSlider.postsBoundsChangedNotifications = true
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(collectionViewDidScroll(_:)),
                                                   name: NSView.boundsDidChangeNotification,
                                                   object: modernSlider.superview)
            
            // Set the modern slider label!
            closestQuarterTimeRepresentation = findClosestQuarterTimeApproximation()
            if let unwrappedClosetQuarterTime = closestQuarterTimeRepresentation {
                modernSliderLabel.stringValue = timezoneFormattedStringRepresentation(unwrappedClosetQuarterTime)
            }
            
            // Make sure modern slider is centered horizontally!
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

    public func findClosestQuarterTimeApproximation() -> Date {
        let defaultParameters = minuteFromCalendar()
        let hourQuarterDate = Calendar.current.nextDate(after: defaultParameters.0,
                                                        matching: DateComponents(minute: defaultParameters.1),
                                                        matchingPolicy: .strict,
                                                        repeatedTimePolicy: .first,
                                                        direction: .forward)!
        return hourQuarterDate
    }

    public func setDefaultDateLabel(_ index: Int) -> Int {
        let totalCount = (PanelConstants.modernSliderPointsInADay * PanelConstants.modernSliderDaySupport * 2) + 1
        let centerPoint = Int(ceil(Double(totalCount / 2)))
        if index > (centerPoint + 1) {
            let remainder = (index % (centerPoint + 1))
            let nextDate = Calendar.current.date(byAdding: .minute, value: remainder * 15, to: closestQuarterTimeRepresentation ?? Date())!
            modernSliderLabel.stringValue = timezoneFormattedStringRepresentation(nextDate)
            return nextDate.minutes(from: Date()) + 1
        } else if index < centerPoint {
            let remainder = centerPoint - index + 1
            let previousDate = Calendar.current.date(byAdding: .minute, value: -1 * remainder * 15, to: closestQuarterTimeRepresentation ?? Date())!
            modernSliderLabel.stringValue = timezoneFormattedStringRepresentation(previousDate)
            return previousDate.minutes(from: Date())
        } else {
            modernSliderLabel.stringValue = "Time Scroller"
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
