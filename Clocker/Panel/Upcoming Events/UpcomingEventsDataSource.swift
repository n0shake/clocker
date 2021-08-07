// Copyright © 2015 Abhishek Banthia

import Foundation

class UpcomingEventsDataSource: NSObject, NSCollectionViewDataSource, NSCollectionViewDelegateFlowLayout {
    private var upcomingEvents: [EventInfo] = []
    
    func updateEventsDataSource(_ events: [EventInfo]) {
        upcomingEvents = events
    }
    
    func collectionView(_: NSCollectionView, numberOfItemsInSection _: Int) -> Int {
        if upcomingEvents.isEmpty {
            return 1
        }
        return upcomingEvents.count
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: UpcomingEventViewItem.reuseIdentifier, for: indexPath) as! UpcomingEventViewItem
        if upcomingEvents.isEmpty {
            let title = NSLocalizedString("See your next Calendar event here.", comment: "Next Event Label for no Calendar access")
            let subtitle = NSLocalizedString("Click here to start.", comment: "Button Title for no Calendar access")
            item.setup(title, subtitle, NSColor(red: 97 / 255.0, green: 194 / 255.0, blue: 80 / 255.0, alpha: 1.0))
            return item
        }
    
        let currentEventInfo = upcomingEvents[indexPath.item]
        let upcomingEventSubtitle = currentEventInfo.isAllDay ? "All-Day" : currentEventInfo.metadataForMeeting()
        item.setup(currentEventInfo.event.title, upcomingEventSubtitle, currentEventInfo.event.calendar.color)
        return item
    }
    
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        if upcomingEvents.isEmpty {
            return NSSize(width: 325, height: 50)
        }
        
        let currentEventInfo = upcomingEvents[indexPath.item]
        let prefferedSize = avenirLightFont.size(currentEventInfo.event.title, 250, attributes: [NSAttributedString.Key.font: avenirLightFont,])
        return NSSize(width: prefferedSize.width, height: 50)
    }
}
