// Copyright © 2015 Abhishek Banthia

import Foundation

class UpcomingEventsDataSource: NSObject, NSCollectionViewDataSource, NSCollectionViewDelegateFlowLayout {
    private var upcomingEvents: [EventInfo] = []
    private var eventCenter: EventCenter!
    private weak var delegate: UpcomingEventPanelDelegate?

    init(_ panelDelegate: UpcomingEventPanelDelegate?, _ center: EventCenter) {
        super.init()
        delegate = panelDelegate
        eventCenter = center
    }

    func updateEventsDataSource(_ events: [EventInfo]) {
        upcomingEvents = events
    }

    func collectionView(_: NSCollectionView, numberOfItemsInSection _: Int) -> Int {
        if eventCenter.calendarAccessDenied() || eventCenter.calendarAccessNotDetermined() || upcomingEvents.isEmpty {
            return 1
        }
        return upcomingEvents.count
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: UpcomingEventViewItem.reuseIdentifier, for: indexPath) as! UpcomingEventViewItem
        if eventCenter.calendarAccessNotDetermined() {
            item.setupUndeterminedState(delegate)
            return item
        }

        if upcomingEvents.isEmpty {
            item.setupEmptyState()
            return item
        }

        let currentEventInfo = upcomingEvents[indexPath.item]
        let upcomingEventSubtitle = currentEventInfo.isAllDay ? "All-Day" : currentEventInfo.metadataForMeeting()
        item.setup(currentEventInfo.event.title, upcomingEventSubtitle, currentEventInfo.event.calendar.color,
                   currentEventInfo.meetingURL, delegate)
        return item
    }

    func collectionView(_ collectionView: NSCollectionView, layout _: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        if upcomingEvents.isEmpty || eventCenter.calendarAccessNotDetermined() {
            return NSSize(width: collectionView.frame.width - 20, height: 50)
        }

        let currentEventInfo = upcomingEvents[indexPath.item]
        let attributedString = NSAttributedString(string: currentEventInfo.event.title, attributes: [NSAttributedString.Key.font : avenirLightFont])
        return NSSize(width: attributedString.size().width + 60, height: 50)
    }
}
