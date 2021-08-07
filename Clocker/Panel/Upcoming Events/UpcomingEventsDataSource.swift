// Copyright © 2015 Abhishek Banthia

import Foundation

class UpcomingEventsDataSource: NSObject, NSCollectionViewDataSource, NSCollectionViewDelegateFlowLayout {
    private var upcomingEvents: [EventInfo] = []
    
    func updateEventsDataSource(_ events: [EventInfo]) {
        upcomingEvents = events
    }
    
    func collectionView(_: NSCollectionView, numberOfItemsInSection _: Int) -> Int {
        return upcomingEvents.count
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: UpcomingEventViewItem.reuseIdentifier, for: indexPath) as! UpcomingEventViewItem
        let currentEventInfo = upcomingEvents[indexPath.item]
        
        let upcomingEventSubtitle = currentEventInfo.isAllDay ? "All-Day" : currentEventInfo.metadataForMeeting()
        item.setup(currentEventInfo.event.title, upcomingEventSubtitle, currentEventInfo.event.calendar.color)
        return item
    }
    
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        let currentEventInfo = upcomingEvents[indexPath.item]
        let prefferedSize = avenirLightFont.size(currentEventInfo.event.title, 250, attributes: [NSAttributedString.Key.font: avenirLightFont,])
        return NSSize(width: prefferedSize.width, height: 50)
    }
}
