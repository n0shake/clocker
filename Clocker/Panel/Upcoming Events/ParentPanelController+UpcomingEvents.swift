// Copyright © 2015 Abhishek Banthia

import Foundation

var avenirLightFont: NSFont {
    if let avenirFont = NSFont(name: "Avenir-Light", size: 12) {
        return avenirFont
    }
    return NSFont.systemFont(ofSize: 12)
}

protocol UpcomingEventPanelDelegate: AnyObject {
    func didRemoveCalendarView()
    func didClickSupplementaryButton(_ sender: NSButton)
}

extension ParentPanelController {
    func setupUpcomingEventViewCollectionViewIfNeccesary() {
        if upcomingEventCollectionView != nil {
            upcomingEventsDataSource = UpcomingEventsDataSource(self, EventCenter.sharedCenter())
            upcomingEventCollectionView.enclosingScrollView?.scrollerInsets = NSEdgeInsetsZero
            upcomingEventCollectionView.enclosingScrollView?.backgroundColor = NSColor.clear
            upcomingEventCollectionView.setAccessibility("UpcomingEventCollectionView")
            upcomingEventCollectionView.dataSource = upcomingEventsDataSource
            upcomingEventCollectionView.delegate = upcomingEventsDataSource
        }
    }
}

extension ParentPanelController: UpcomingEventPanelDelegate {
    func didRemoveCalendarView() {
        removeUpcomingEventView()
    }

    func didClickSupplementaryButton(_ sender: NSButton) {
        calendarButtonAction(sender)
    }
}
