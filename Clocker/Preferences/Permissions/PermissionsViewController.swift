// Copyright © 2015 Abhishek Banthia

import Cocoa

class PermissionsViewController: ParentViewController {

    @IBOutlet var calendarContainerView: NSView!
    @IBOutlet var remindersContainerView: NSView!

    @IBOutlet private var calendarButton: NSButton!
    @IBOutlet private var remindersButton: NSButton!

    @IBOutlet private var calendarActivity: NSProgressIndicator!
    @IBOutlet private var remindersActivity: NSProgressIndicator!

    @IBOutlet private var reminderHeaderLabel: NSTextField!
    @IBOutlet private var reminderDetailLabel: NSTextField!

    @IBOutlet private var calendarHeaderLabel: NSTextField!
    @IBOutlet private var calendarDetailLabel: NSTextField!

    @IBOutlet private var privacyLabel: NSTextField!
    @IBOutlet private var headerLabel: NSTextField!

    private var themeDidChangeNotification: NSObjectProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        [calendarContainerView, remindersContainerView].forEach { $0?.applyShadow() }
        setupLocalizedText()

        themeDidChangeNotification = NotificationCenter.default.addObserver(forName: .themeDidChangeNotification, object: nil, queue: OperationQueue.main) { _ in
            self.setupLocalizedText()
            [self.calendarContainerView, self.remindersContainerView].forEach { $0?.applyShadow() }
        }
    }

    override func viewWillAppear() {
        super.viewDidLoad()
        setup()
    }

    deinit {
        if let themeDidChangeNotif = themeDidChangeNotification {
            NotificationCenter.default.removeObserver(themeDidChangeNotif)
        }
    }

    private func setup() {
        setupButtons()
    }

    private func setupLocalizedText() {
        headerLabel.stringValue = "Permissions"

        reminderHeaderLabel.stringValue = "Reminders Access"
        reminderDetailLabel.stringValue = "Set reminders in the timezone of the location of your choice. Your reminders are stored in the default Reminders app. "

        calendarHeaderLabel.stringValue = "Calendar Access"
        calendarDetailLabel.stringValue = "Upcoming events from your personal and shared calendars can be shown in the menubar and the panel."

        privacyLabel.stringValue = "You can change this later in the Privacy section of the System Preferences."

        [calendarHeaderLabel, calendarDetailLabel, privacyLabel, reminderDetailLabel, reminderHeaderLabel, headerLabel].forEach { $0?.textColor = Themer.shared().mainTextColor()
        }
    }

    private func setupButtons() {
        /*
         if LocationController.sharedInstance.locationAccessGranted() {
         locationButton.title = "Granted"
         } else if LocationController.sharedInstance.locationAccessDenied() {
         locationButton.title = "Denied"
         } else if LocationController.sharedInstance.locationAccessNotDetermined() {
         locationButton.title = "Grant"
         } else {
         locationButton.title = "Unexpected"
         } */

        if EventCenter.sharedCenter().calendarAccessGranted() {
            calendarButton.title = "Granted"
        } else if EventCenter.sharedCenter().calendarAccessDenied() {
            calendarButton.title = "Denied"
        } else if EventCenter.sharedCenter().calendarAccessNotDetermined() {
            calendarButton.title = "Grant"
        } else {
            calendarButton.title = "Unexpected"
        }

        if EventCenter.sharedCenter().reminderAccessGranted() {
            remindersButton.title = "Granted"
        } else if EventCenter.sharedCenter().reminderAccessDenied() {
            remindersButton.title = "Denied"
        } else if EventCenter.sharedCenter().reminderAccessNotDetermined() {
            remindersButton.title = "Grant"
        } else {
            remindersButton.title = "Unexpected"
        }
    }

    @IBAction func locationAction(_: Any) {
        /*
         let locationCenter = LocationController.sharedInstance

         if locationCenter.locationAccessNotDetermined() {
         locationCenter.determineAndRequestLocationAuthorization()
         } else if locationCenter.locationAccessGranted() {
         OperationQueue.main.addOperation {
         self.locationButton.title = "Granted"
         }
         } else if locationCenter.locationAccessDenied() {
         OperationQueue.main.addOperation {
         self.locationButton.title = "Denied"
         }
         }*/
    }

    @IBAction func calendarAction(_: Any) {
        let eventCenter = EventCenter.sharedCenter()

        if eventCenter.calendarAccessNotDetermined() {
            calendarActivity.startAnimation(nil)

            eventCenter.requestAccess(to: .event, completionHandler: { granted in

                OperationQueue.main.addOperation {
                    self.calendarActivity.stopAnimation(nil)
                }

                if granted {
                    OperationQueue.main.addOperation {

                        self.view.window?.orderBack(nil)
                        NSApp.activate(ignoringOtherApps: true)

                        self.calendarButton.title = "Granted"

                        // Used to update CalendarViewController's view
                        NotificationCenter.default.post(name: .calendarAccessGranted, object: nil)
                    }
                } else {
                    Logger.log(object: ["Reminder Access Not Granted": "YES"], for: "Reminder Access Not Granted")
                }
            })
        } else if eventCenter.calendarAccessGranted() {
            calendarButton.title = "Granted"
        } else {
            calendarButton.title = "Denied"
        }
    }

    @IBAction func remindersAction(_: NSButton) {
        let eventCenter = EventCenter.sharedCenter()

        if eventCenter.reminderAccessNotDetermined() {
            remindersActivity.startAnimation(nil)

            eventCenter.requestAccess(to: .reminder, completionHandler: { granted in

                OperationQueue.main.addOperation {
                    self.remindersActivity.stopAnimation(nil)
                }

                if granted {
                    OperationQueue.main.addOperation {

                        self.view.window?.orderBack(nil)
                        NSApp.activate(ignoringOtherApps: true)

                        self.remindersButton.title = "Granted"
                    }
                } else {
                    Logger.log(object: ["Reminder Access Not Granted": "YES"], for: "Reminder Access Not Granted")
                }
            })
        } else if eventCenter.reminderAccessGranted() {
            remindersButton.title = "Granted"
        } else {
            remindersButton.title = "Denied"
        }
    }
}

extension NSView {
    func applyShadow() {
        wantsLayer = true
        layer?.masksToBounds = true
        layer?.cornerRadius = 12
        layer?.backgroundColor = Themer.shared().textBackgroundColor().cgColor
    }
}

extension NSButton {
    func setBackgroundColor(color: NSColor) {
        wantsLayer = true
        layer?.backgroundColor = color.cgColor
    }
}
