// Copyright © 2015 Abhishek Banthia

import AppKit
import Foundation

class UpcomingEventsDataSource: NSObject, NSCollectionViewDataSource, NSCollectionViewDelegateFlowLayout {
    private var upcomingEvents: [EventInfo] = []
    private var eventCenter: EventCenter!
    private weak var delegate: UpcomingEventPanelDelegate?
    private static let panelWidth: CGFloat = 300.0

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
        guard let item = collectionView.makeItem(withIdentifier: UpcomingEventViewItem.reuseIdentifier, for: indexPath) as? UpcomingEventViewItem else {
            assertionFailure("Unable to make UpcomingEventViewItem")
            return NSCollectionViewItem()
        }
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
        item.setup(currentEventInfo.event.title,
                   upcomingEventSubtitle,
                   currentEventInfo.event.calendar.color,
                   currentEventInfo.meetingURL,
                   delegate,
                   currentEventInfo.event.status == .canceled)
        return item
    }

    func collectionView(_ collectionView: NSCollectionView, layout _: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        if eventCenter.calendarAccessNotDetermined() {
            return NSSize(width: UpcomingEventsDataSource.panelWidth - 25, height: collectionView.frame.height - 15)
        } else if upcomingEvents.isEmpty {
            return NSSize(width: UpcomingEventsDataSource.panelWidth - 25, height: collectionView.frame.height - 15)
        } else {
            let currentEventInfo = upcomingEvents[indexPath.item]
            let bufferWidth: CGFloat = currentEventInfo.meetingURL != nil ? 60.0 : 20.0
            let longerString = currentEventInfo.event.title.count >= currentEventInfo.metadataForMeeting().count ? currentEventInfo.event.title : currentEventInfo.metadataForMeeting()
            let attributedString = NSAttributedString(string: longerString ?? CLEmptyString, attributes: [NSAttributedString.Key.font: avenirBookFont])
            let maxWidth = min((attributedString.size().width + 15) + bufferWidth, UpcomingEventsDataSource.panelWidth / 2)
            return NSSize(width: maxWidth, height: collectionView.frame.height - 20)
        }
    }
}
