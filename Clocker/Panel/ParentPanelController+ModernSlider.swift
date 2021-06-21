// Copyright © 2015 Abhishek Banthia

import CoreLoggerKit
import Foundation

extension ParentPanelController: NSCollectionViewDataSource, NSCollectionViewDelegate {
    func collectionView(_: NSCollectionView, numberOfItemsInSection _: Int) -> Int {
        return 96
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: HourMarkerViewItem.reuseIdentifier, for: indexPath) as! HourMarkerViewItem
        item.setup(with: indexPath.item)
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
            setModernSliderLabel(item.indexTag)
            setTimezoneDatasourceSlider(sliderValue: item.indexTag * 15)
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

    func setModernSliderLabel(_ index: Int) {
        var dateComponents = DateComponents()
        dateComponents.minute = index * 15
        if let newDate = Calendar.autoupdatingCurrent.date(byAdding: dateComponents, to: Date().nextHour) {
            let dateFormatter = DateFormatterManager.dateFormatterWithFormat(with: .none,
                                                                             format: "MMM d HH:mm",
                                                                             timezoneIdentifier: TimeZone.current.identifier,
                                                                             locale: Locale.autoupdatingCurrent)

            modernSliderLabel.stringValue = dateFormatter.string(from: newDate)
        }
    }
}
