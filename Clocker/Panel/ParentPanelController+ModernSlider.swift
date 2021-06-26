// Copyright © 2015 Abhishek Banthia

import CoreLoggerKit
import Foundation

extension ParentPanelController: NSCollectionViewDataSource, NSCollectionViewDelegate {
    func collectionView(_: NSCollectionView, numberOfItemsInSection _: Int) -> Int {
        return modernSliderDataSource.count
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: HourMarkerViewItem.reuseIdentifier, for: indexPath) as! HourMarkerViewItem
        let dataSoureValue = modernSliderDataSource[indexPath.item]
        item.setup(with: indexPath.item, value: dataSoureValue)
        return item
    }
}

extension ParentPanelController {
    @objc func collectionViewDidScroll(_ notification: NSNotification) {
        let contentView = notification.object as! NSClipView
        let changedOrigin = contentView.documentVisibleRect.origin
        let newPoint = NSPoint(x: changedOrigin.x + contentView.frame.width / 2, y: changedOrigin.y)
        let indexPath = modernSlider.indexPathForItem(at: newPoint)
        if let correctIndexPath = indexPath?.item, let item = modernSlider.item(at: correctIndexPath) as? HourMarkerViewItem {
            modernSliderLabel.stringValue = item.timeRepresentation
//            setTimezoneDatasourceSlider(sliderValue: item.indexTag * 15)
            item.setupLineColor()
            mainTableView.reloadData()

            if let previousItem = modernSlider.item(at: correctIndexPath - 1) as? HourMarkerViewItem {
                previousItem.resetLineColor()
            }
            if let nextItem = modernSlider.item(at: correctIndexPath + 1) as? HourMarkerViewItem {
                nextItem.resetLineColor()
            }
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

    public func forward15Minutes() -> [String] {
        let defaultParameters = minuteFromCalendar()
        let hourQuarterDate = Calendar.current.nextDate(after: defaultParameters.0, matching: DateComponents(minute: defaultParameters.1), matchingPolicy: .strict, repeatedTimePolicy: .first, direction: .forward)!
        var backwards = hourQuarterDate
        var forwards = hourQuarterDate

        var hourQuarters = [String]()
        for _ in 1 ... 96 {
            backwards = Calendar.current.date(byAdding: .minute, value: -15, to: backwards)!
            hourQuarters.append(timezoneFormattedStringRepresentation(backwards))
        }

        hourQuarters.append(timezoneFormattedStringRepresentation(forwards))
        for _ in 1 ... 96 {
            forwards = Calendar.current.date(byAdding: .minute, value: 15, to: forwards)!
            hourQuarters.append(timezoneFormattedStringRepresentation(forwards))
        }
        return hourQuarters
    }

    public func backward15Minutes() -> [String] {
        let defaultParameters = minuteFromCalendar()
        var hourQuarterDate = Calendar.current.nextDate(after: defaultParameters.0, matching: DateComponents(minute: defaultParameters.1), matchingPolicy: .strict, repeatedTimePolicy: .first, direction: .forward)!
        var hourQuarters = [String]()
        for _ in 1 ... 96 {
            hourQuarterDate = Calendar.current.date(byAdding: .minute, value: -15, to: hourQuarterDate)!
            hourQuarters.append(timezoneFormattedStringRepresentation(hourQuarterDate))
        }

        return hourQuarters
    }

    private func timezoneFormattedStringRepresentation(_ date: Date) -> String {
        let dateFormatter = DateFormatterManager.dateFormatterWithFormat(with: .none,
                                                                         format: "MMM d HH:mm",
                                                                         timezoneIdentifier: TimeZone.current.identifier,
                                                                         locale: Locale.autoupdatingCurrent)
        return dateFormatter.string(from: date)
    }
}
