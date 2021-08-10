// Copyright © 2015 Abhishek Banthia

import Foundation

class UpcomingEventViewItem: NSCollectionViewItem {
    static let reuseIdentifier = NSUserInterfaceItemIdentifier("UpcomingEventViewItem")

    @IBOutlet var calendarColorView: NSView!
    @IBOutlet var leadingConstraint: NSLayoutConstraint!
    @IBOutlet var eventTitleLabel: NSTextField!
    @IBOutlet var eventSubtitleButton: NSButton!
    @IBOutlet var zoomButton: NSButton!

    private var meetingLink: URL?
    private weak var panelDelegate: UpcomingEventPanelDelegate?

    override func viewDidLoad() {
        zoomButton.target = self
        zoomButton.action = #selector(zoomButtonAction(_:))
    }

    func setup(_ title: String,
               _ subtitle: String,
               _ color: NSColor,
               _ meetingURL: URL?,
               _ delegate: UpcomingEventPanelDelegate?) {
        if leadingConstraint.constant != 5 {
            leadingConstraint.constant = 5
        }

        calendarColorView.layer?.backgroundColor = color.cgColor
        eventTitleLabel.stringValue = title
        setCalendarButtonTitle(buttonTitle: subtitle)
        panelDelegate = delegate

        if meetingURL != nil {
            meetingLink = meetingURL
            zoomButton.image = Themer.shared().videoCallImage()
        }
    }

    func setupUndeterminedState(_ delegate: UpcomingEventPanelDelegate?) {
        if leadingConstraint.constant != 10 {
            leadingConstraint.constant = 10
        }

        eventTitleLabel.stringValue = NSLocalizedString("See your next Calendar event here.", comment: "Next Event Label for no Calendar access")
        setCalendarButtonTitle(buttonTitle: NSLocalizedString("Click here to start.", comment: "Button Title for no Calendar access"))
        calendarColorView.layer?.backgroundColor = NSColor.systemBlue.cgColor
        zoomButton.image = Themer.shared().removeImage()
        panelDelegate = delegate
    }

    func setupEmptyState() {
        if leadingConstraint.constant != 10 {
            leadingConstraint.constant = 10
        }

        eventTitleLabel.stringValue = NSLocalizedString("No upcoming events for today!", comment: "Next Event Label with no upcoming event")
        setCalendarButtonTitle(buttonTitle: NSLocalizedString("Inbox Zero!", comment: "Button Title for no upcoming event"))
        calendarColorView.layer?.backgroundColor = NSColor.systemGreen.cgColor
        zoomButton.image = Themer.shared().removeImage()
    }

    private func setCalendarButtonTitle(buttonTitle: String) {
        let style = NSMutableParagraphStyle()
        style.alignment = .left
        style.lineBreakMode = .byTruncatingTail

        if let boldFont = NSFont(name: "Avenir", size: 11) {
            let attributes = [NSAttributedString.Key.foregroundColor: NSColor.gray, NSAttributedString.Key.paragraphStyle: style, NSAttributedString.Key.font: boldFont]

            let attributedString = NSAttributedString(string: buttonTitle, attributes: attributes)
            eventSubtitleButton.attributedTitle = attributedString
            eventSubtitleButton.toolTip = attributedString.string
        }
    }

    override var acceptsFirstResponder: Bool {
        return false
    }

    @IBAction func calendarButtonAction(_ sender: NSButton) {
        panelDelegate?.didClickSupplementaryButton(sender)
    }

    @objc func zoomButtonAction(_: Any) {
        if let meetingURL = meetingLink {
            NSWorkspace.shared.open(meetingURL)
        } else {
            panelDelegate?.didRemoveCalendarView()
        }
    }
}
