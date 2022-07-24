// Copyright © 2015 Abhishek Banthia

import Cocoa
import CoreLoggerKit

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
        headerLabel.stringValue = NSLocalizedString("Permissions", comment: "Permissions Tab Titles")

        reminderHeaderLabel.stringValue = NSLocalizedString("Reminders Access",
                                                            comment: "Reminders Permission Title")
        reminderDetailLabel.stringValue = NSLocalizedString("Reminders Detail",
                                                            comment: "Reminders Detail Text")

        calendarHeaderLabel.stringValue = NSLocalizedString("Calendar Access",
                                                            comment: "Calendar Permission Title")
        calendarDetailLabel.stringValue = NSLocalizedString("Calendar Detail",
                                                            comment: "Calendar Detail Text")

        privacyLabel.stringValue = NSLocalizedString("Privacy Text",
                                                     comment: "Text explaining options can be changed in the future through System Preferences")
        [calendarHeaderLabel, calendarDetailLabel, privacyLabel, reminderDetailLabel, reminderHeaderLabel, headerLabel].forEach { $0?.textColor = Themer.shared().mainTextColor()
        }
    }

    private func setupButtons() {
        calendarButton.setAccessibility("CalendarGrantAccessButton")
        remindersButton.setAccessibility("RemindersGrantAccessButton")
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
            calendarButton.title = NSLocalizedString("Granted Button Text",
                                                     comment: "Granted Button Text")
        } else if EventCenter.sharedCenter().calendarAccessDenied() {
            calendarButton.title = NSLocalizedString("Denied Button Text",
                                                     comment: "Denied Button Text")
        } else if EventCenter.sharedCenter().calendarAccessNotDetermined() {
            calendarButton.title = NSLocalizedString("Grant Button Text",
                                                     comment: "Grant Button Text")
        } else {
            calendarButton.title = "Unexpected".localized()
        }

        if EventCenter.sharedCenter().reminderAccessGranted() {
            remindersButton.title = NSLocalizedString("Granted Button Text",
                                                      comment: "Granted Button Text")
        } else if EventCenter.sharedCenter().reminderAccessDenied() {
            remindersButton.title = NSLocalizedString("Denied Button Text",
                                                      comment: "Denied Button Text")
        } else if EventCenter.sharedCenter().reminderAccessNotDetermined() {
            remindersButton.title = NSLocalizedString("Grant Button Text",
                                                      comment: "Grant Button Text")
        } else {
            remindersButton.title = "Unexpected".localized()
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

                        self.calendarButton.title = NSLocalizedString("Granted Button Text",
                                                                      comment: "Granted Button Text")

                        // Used to update CalendarViewController's view
                        NotificationCenter.default.post(name: .calendarAccessGranted, object: nil)
                    }
                } else {
                    Logger.log(object: ["Calendar Access Not Granted": "YES"],
                               for: "Calendar Access Not Granted")
                }
            })
        } else if eventCenter.calendarAccessGranted() {
            calendarButton.title = NSLocalizedString("Granted Button Text",
                                                     comment: "Granted Button Text")
        } else {
            calendarButton.title = NSLocalizedString("Denied Button Text",
                                                     comment: "Denied Button Text")
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

                        self.remindersButton.title = NSLocalizedString("Granted Button Text",
                                                                       comment: "Granted Button Text")
                    }
                } else {
                    Logger.log(object: ["Reminder Access Not Granted": "YES"], for: "Reminder Access Not Granted")
                }
            })
        } else if eventCenter.reminderAccessGranted() {
            remindersButton.title = NSLocalizedString("Granted Button Text",
                                                      comment: "Granted Button Text")
        } else {
            remindersButton.title = NSLocalizedString("Denied Button Text",
                                                      comment: "Denied Button Text")
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
