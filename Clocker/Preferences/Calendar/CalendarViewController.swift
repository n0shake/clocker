// Copyright © 2015 Abhishek Banthia

import Cocoa
import CoreLoggerKit
import EventKit

class ClockerTextBackgroundView: NSView {
    override func awakeFromNib() {
        wantsLayer = true
        layer?.cornerRadius = 8.0
        layer?.masksToBounds = false
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateBackgroundColor),
                                               name: .themeDidChangeNotification,
                                               object: nil)
    }
    
    override func updateLayer() {
        super.updateLayer()
        layer?.backgroundColor = Themer.shared().textBackgroundColor().cgColor
    }
    
    @objc func updateBackgroundColor() {
        layer?.backgroundColor = Themer.shared().textBackgroundColor().cgColor
    }
}

class CalendarViewController: ParentViewController {
    @IBOutlet var showSegmentedControl: NSSegmentedControl!
    @IBOutlet var allDaysSegmentedControl: NSSegmentedControl!
    @IBOutlet var truncateTextField: NSTextField!
    @IBOutlet var noAccessView: NSVisualEffectView!
    @IBOutlet var informationField: NSTextField!
    @IBOutlet var grantAccessButton: NSButton!
    @IBOutlet var calendarsTableView: NSTableView!
    
    @IBOutlet var showNextMeetingInMenubarControl: NSSegmentedControl!
    @IBOutlet var backgroundView: NSView!
    @IBOutlet var nextMeetingBackgroundView: NSView!
    private var themeDidChangeNotification: NSObjectProtocol?
    
    private lazy var calendars: [Any] = EventCenter.sharedCenter().fetchSourcesAndCalendars()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(calendarAccessStatusChanged),
                                               name: .calendarAccessGranted,
                                               object: nil)
        
        themeDidChangeNotification = NotificationCenter.default.addObserver(forName: .themeDidChangeNotification, object: nil, queue: OperationQueue.main) { _ in
            self.setup()
        }
        
        noAccessView.material = .contentBackground
        upcomingEventView.setAccessibility("UpcomingEventView")
    }
    
    deinit {
        if let themeDidChangeNotif = themeDidChangeNotification {
            NotificationCenter.default.removeObserver(themeDidChangeNotif)
        }
    }
    
    @objc func calendarAccessStatusChanged() {
        verifyCalendarAccess()
        
        view.window?.windowController?.showWindow(nil)
        view.window?.makeKeyAndOrderFront(nil)
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        verifyCalendarAccess()
        showSegmentedControl.selectedSegment = DataStore.shared().shouldDisplay(ViewType.upcomingEventView) ? 0 : 1
    }
    
    private func verifyCalendarAccess() {
        let hasCalendarAccess = EventCenter.sharedCenter().calendarAccessGranted()
        let hasNotDeterminedCalendarAccess = EventCenter.sharedCenter().calendarAccessNotDetermined()
        let hasDeniedCalendarAccess = EventCenter.sharedCenter().calendarAccessDenied()
        
        noAccessView.isHidden = hasCalendarAccess
        
        if hasNotDeterminedCalendarAccess {
            informationField.stringValue = "Clocker is more useful when it can display events from your calendars.".localized()
            setGrantAccess(title: "Grant Access".localized())
        } else if hasDeniedCalendarAccess {
            // The informationField text is taken care off in the XIB. Just set the grant button to empty because we can't do anything.
            setGrantAccess(title: UserDefaultKeys.emptyString)
        } else {
            calendarsTableView.reloadData()
        }
    }
    
    private func setGrantAccess(title: String) {
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        
        guard let boldFont = NSFont(name: "Avenir-Medium", size: 14.0) else { return }
        
        let attributesDictionary: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.paragraphStyle: style,
            NSAttributedString.Key.font: boldFont,
            NSAttributedString.Key.foregroundColor: Themer.shared().mainTextColor(),
        ]
        let attributedString = NSAttributedString(string: title,
                                                  attributes: attributesDictionary)
        grantAccessButton.attributedTitle = attributedString
    }
    
    private func onCalendarAccessDenial() {
        informationField.stringValue = """
         Clocker is more useful when it can display events from your calendars.
         You can change this setting in System Preferences › Security & Privacy › Privacy.
        """.localized()
        setGrantAccess(title: "Launch Preferences".localized())
        
        // Remove upcoming event view if possible
        UserDefaults.standard.set("NO", forKey: UserDefaultKeys.showUpcomingEventView)
    }
    
    @IBAction func grantAccess(_: Any) {
        if grantAccessButton.title == "Grant Access".localized() {
            (parent as? CenteredTabViewController)?.selectedTabViewItemIndex = 3 // 3 is the Permissions View
        } else if grantAccessButton.title == "Launch Preferences" {
            NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/System Settings.app"))
        }
    }
    
    @IBAction func showNextMeetingAction(_ sender: NSSegmentedControl) {
        // We need to start the menubar timer if it hasn't been started already
        guard let delegate = NSApplication.shared.delegate as? AppDelegate else {
            assertionFailure()
            return
        }
        
        let statusItemHandler = delegate.statusItemForPanel()
        
        if sender.selectedSegment == 0 {
            if let isValid = statusItemHandler.menubarTimer?.isValid, isValid == true {
                Logger.info("Timer is already in progress")
                updateStatusItem()
                return
            }
            
        } else {
            statusItemHandler.invalidateTimer(showIcon: true, isSyncing: false)
        }
    }
    
    @IBAction func showUpcomingEventView(_ sender: NSSegmentedControl) {
        var showUpcomingEventView = "YES"
        
        if sender.selectedSegment == 1 {
            showUpcomingEventView = "NO"
        }
        
        UserDefaults.standard.set(showUpcomingEventView, forKey: UserDefaultKeys.showUpcomingEventView)
        
        if DataStore.shared().shouldDisplay(ViewType.showAppInForeground) {
            let floatingWindow = FloatingWindowController.shared()
            floatingWindow.determineUpcomingViewVisibility()
            return
        }
        
        guard let panel = PanelController.panel() else { return }
        if sender.selectedSegment == 1 {
            panel.removeUpcomingEventView()
            Logger.log(object: ["Show": "NO"], for: "Upcoming Event View")
        } else {
            panel.showUpcomingEventView()
            Logger.log(object: ["Show": "YES"], for: "Upcoming Event View")
        }
    }
    
    private func updateStatusItem() {
        guard let statusItem = (NSApplication.shared.delegate as? AppDelegate)?.statusItemForPanel() else {
            return
        }
        
        statusItem.refresh()
    }
    
    @IBOutlet var headerLabel: NSTextField!
    @IBOutlet var upcomingEventView: NSTextField!
    @IBOutlet var allDayMeetingsLabel: NSTextField!
    @IBOutlet var showNextMeetingLabel: NSTextField!
    @IBOutlet var nextMeetingAccessoryLabel: NSTextField!
    @IBOutlet var truncateTextLabel: NSTextField!
    @IBOutlet var showEventsFromLabel: NSTextField!
    @IBOutlet var charactersField: NSTextField!
    @IBOutlet var truncateAccessoryLabel: NSTextField!
    
    private func setup() {
        // Grant access button's text color is taken care above.
        headerLabel.stringValue = "Upcoming Event View Options".localized()
        upcomingEventView.stringValue = "Show Upcoming Event View".localized()
        allDayMeetingsLabel.stringValue = "Show All Day Meetings".localized()
        showNextMeetingLabel.stringValue = "Show Next Meeting Title in Menubar".localized()
        truncateTextLabel.stringValue = "Truncate menubar text longer than".localized()
        charactersField.stringValue = "characters".localized()
        showEventsFromLabel.stringValue = "Show events from".localized()
        truncateAccessoryLabel.stringValue = "If meeting title is \"Meeting with Neel\" and truncate length is set to 5, text in menubar will appear as \"Meeti...\"".localized()
        
        [headerLabel, upcomingEventView, allDayMeetingsLabel,
         showNextMeetingLabel, nextMeetingAccessoryLabel, truncateTextLabel,
         showEventsFromLabel, charactersField, truncateAccessoryLabel].forEach { $0?.textColor = Themer.shared().mainTextColor() }
        
        calendarsTableView.backgroundColor = Themer.shared().mainBackgroundColor()
        truncateTextField.backgroundColor = Themer.shared().mainBackgroundColor()
    }
}

extension CalendarViewController: NSTableViewDataSource {
    func numberOfRows(in _: NSTableView) -> Int {
        let hasCalendarAccess = EventCenter.sharedCenter().calendarAccessGranted()
        return hasCalendarAccess ? calendars.count : 0
    }
}

extension CalendarViewController: NSTableViewDelegate {
    func tableView(_: NSTableView, shouldSelectRow _: Int) -> Bool {
        return false
    }
    
    func tableView(_: NSTableView, heightOfRow row: Int) -> CGFloat {
        guard let currentSource = calendars[row] as? String, !currentSource.isEmpty else {
            return 30.0
        }
        
        return 24.0
    }
    
    func tableView(_ tableView: NSTableView, viewFor _: NSTableColumn?, row: Int) -> NSView? {
        if let currentSource = calendars[row] as? String,
           let message = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "sourceCellView"), owner: self) as? SourceTableViewCell
        {
            message.sourceName.stringValue = currentSource
            return message
        }
        
        if let currentSource = calendars[row] as? CalendarInfo,
           let calendarCell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "calendarCellView"), owner: self) as? CalendarTableViewCell
        {
            calendarCell.calendarName.stringValue = currentSource.calendar.title
            calendarCell.calendarSelected.state = currentSource.selected ? NSControl.StateValue.on : NSControl.StateValue.off
            calendarCell.calendarSelected.target = self
            calendarCell.calendarSelected.tag = row
            calendarCell.calendarSelected.wantsLayer = true
            calendarCell.calendarSelected.action = #selector(calendarSelected(_:))
            return calendarCell
        }
        
        return nil
    }
    
    @objc func calendarSelected(_ checkbox: NSButton) {
        let currentSelection = checkbox.tag
        
        var sourcesAndCalendars = calendars
        
        if var calInfo = sourcesAndCalendars[currentSelection] as? CalendarInfo {
            calInfo.selected = (checkbox.state == .on)
            sourcesAndCalendars[currentSelection] = calInfo
        }
        
        updateSelectedCalendars(sourcesAndCalendars)
    }
    
    private func updateSelectedCalendars(_ selection: [Any]) {
        var selectedCalendars: [String] = []
        
        for obj in selection {
            if let calInfo = obj as? CalendarInfo, calInfo.selected {
                selectedCalendars.append(calInfo.calendar.calendarIdentifier)
            }
        }
        
        UserDefaults.standard.set(selectedCalendars, forKey: UserDefaultKeys.selectedCalendars)
        
        calendars = EventCenter.sharedCenter().fetchSourcesAndCalendars()
        
        EventCenter.sharedCenter().filterEvents()
    }
}

class SourceTableViewCell: NSTableCellView {
    @IBOutlet var sourceName: NSTextField!
}

class CalendarTableViewCell: NSTableCellView {
    @IBOutlet var calendarName: NSTextField!
    @IBOutlet var calendarSelected: NSButton!
}
