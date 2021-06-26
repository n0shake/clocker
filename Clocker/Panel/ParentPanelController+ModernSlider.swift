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
        if let correctIndexPath = indexPath?.item {
            modernSliderLabel.stringValue = modernSliderDataSource[correctIndexPath]
//            setTimezoneDatasourceSlider(sliderValue: item.indexTag * 15)
//            mainTableView.reloadData()
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
        var hourQuarterDate = Calendar.current.nextDate(after: defaultParameters.0, matching: DateComponents(minute: defaultParameters.1), matchingPolicy: .strict, repeatedTimePolicy: .first, direction: .forward)!

        var hourQuarters = [String]()
        hourQuarters.append(timezoneFormattedStringRepresentation(hourQuarterDate))
        for _ in 1 ... 288 {
            hourQuarterDate = Calendar.current.date(byAdding: .minute, value: 15, to: hourQuarterDate)!
            hourQuarters.append(timezoneFormattedStringRepresentation(hourQuarterDate))
        }
        return hourQuarters
    }

    public func backward15Minutes() -> [String] {
        let defaultParameters = minuteFromCalendar()
        var hourQuarterDate = Calendar.current.nextDate(after: defaultParameters.0, matching: DateComponents(minute: defaultParameters.1), matchingPolicy: .strict, repeatedTimePolicy: .first, direction: .backward)!
        var hourQuarters = [String]()
        for _ in 1 ... 288 {
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
