// Copyright © 2015 Abhishek Banthia

import Foundation

var avenirLightFont: NSFont {
    if let avenirFont = NSFont(name: "Avenir-Light", size: 12) {
        return avenirFont
    }
    return NSFont.systemFont(ofSize: 12)
}

extension ParentPanelController {
    func setupUpcomingEventViewCollectionViewIfNeccesary() {
        if upcomingEventCollectionView != nil {
            upcomingEventCollectionView.enclosingScrollView?.scrollerInsets = NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            upcomingEventCollectionView.enclosingScrollView?.backgroundColor = NSColor.clear
            upcomingEventCollectionView.setAccessibility("UpcomingEventCollectionView")
            upcomingEventCollectionView.dataSource = upcomingEventsDataSource
            upcomingEventCollectionView.delegate = upcomingEventsDataSource
        }
    }
}
