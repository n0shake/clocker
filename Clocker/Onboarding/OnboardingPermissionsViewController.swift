// Copyright © 2015 Abhishek Banthia

import Cocoa
import CoreLoggerKit

class OnboardingPermissionsViewController: NSViewController {
    @IBOutlet var reminderGrantButton: NSButton!
    @IBOutlet var calendarGrantButton: NSButton!

    @IBOutlet var reminderView: NSView!
    @IBOutlet var calendarView: NSView!
    @IBOutlet var locationView: NSView!

    @IBOutlet var reminderActivityIndicator: NSProgressIndicator!
    @IBOutlet var calendarActivityIndicator: NSProgressIndicator!
    @IBOutlet var locationActivityIndicator: NSProgressIndicator!

    @IBOutlet var appLabel: NSTextField!
    @IBOutlet var onboardingTypeLabel: NSTextField!

    @IBOutlet var reminderHeaderLabel: NSTextField!
    @IBOutlet var reminderDetailLabel: NSTextField!

    @IBOutlet var calendarHeaderLabel: NSTextField!
    @IBOutlet var calendarDetailLabel: NSTextField!
    
    @IBOutlet var locationHeaderLabel: NSTextField!
    @IBOutlet var locationDetailLabel: NSTextField!

    @IBOutlet var privacyLabel: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        [calendarView, reminderView].forEach { $0?.applyShadow() }
        setup()
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        setupButtons()
    }

    private func setup() {
        appLabel.stringValue = NSLocalizedString("Permissions Tab",
                                                 comment: "Title for Permissions screen")
        onboardingTypeLabel.stringValue = "Your data doesn't leave your device 🔐"

        reminderHeaderLabel.stringValue = NSLocalizedString("Reminders Access Title",
                                                            comment: "Title for Reminders Access Label")
        reminderDetailLabel.stringValue = "Set reminders in the timezone of the location of your choice. Your reminders are stored in the default Reminders app. "

        calendarHeaderLabel.stringValue = NSLocalizedString("Calendar Access Title",
                                                            comment: "Title for Calendar access label")
        calendarDetailLabel.stringValue = "Calendar Detail".localized()

        privacyLabel.stringValue = CLEmptyString

        [calendarHeaderLabel, calendarDetailLabel, privacyLabel, reminderDetailLabel, reminderHeaderLabel, onboardingTypeLabel, appLabel].forEach { $0?.textColor = Themer.shared().mainTextColor()
        }
    }

    private func setupButtons() {
//         if LocationController.sharedInstance.locationAccessGranted() {
//             locationButton.title = "Granted"
//         } else if LocationController.sharedInstance.locationAccessDenied() {
//             locationButton.title = "Denied"
//         } else if LocationController.sharedInstance.locationAccessNotDetermined() {
//             locationButton.title = "Grant"
//         } else {
//             locationButton.title = "Unexpected"
//         }

        if EventCenter.sharedCenter().calendarAccessGranted() {
            calendarGrantButton.title = "Granted".localized()
        } else if EventCenter.sharedCenter().calendarAccessDenied() {
            calendarGrantButton.title = "Denied".localized()
        } else if EventCenter.sharedCenter().calendarAccessNotDetermined() {
            calendarGrantButton.title = "Grant".localized()
        } else {
            calendarGrantButton.title = "Unexpected".localized()
        }

        if EventCenter.sharedCenter().reminderAccessGranted() {
            reminderGrantButton.title = "Granted".localized()
        } else if EventCenter.sharedCenter().reminderAccessDenied() {
            reminderGrantButton.title = "Denied".localized()
        } else if EventCenter.sharedCenter().reminderAccessNotDetermined() {
            reminderGrantButton.title = "Grant".localized()
        } else {
            reminderGrantButton.title = "Unexpected".localized()
        }
    }

    @IBAction func calendarAction(_: Any) {
        let eventCenter = EventCenter.sharedCenter()

        if eventCenter.calendarAccessNotDetermined() {
            calendarActivityIndicator.startAnimation(nil)

            eventCenter.requestAccess(to: .event, completionHandler: { [weak self] granted in
                OperationQueue.main.addOperation {
                    guard let self = self else { return }

                    self.calendarActivityIndicator.stopAnimation(nil)

                    if granted {
                        self.calendarGrantButton.title = "Granted".localized()

                        self.view.window?.orderBack(nil)
                        NSApp.activate(ignoringOtherApps: true)

                        // Used to update CalendarViewController's view
                        NotificationCenter.default.post(name: .calendarAccessGranted, object: nil)

                    } else {
                        Logger.log(object: ["Reminder Access Not Granted": "YES"], for: "Reminder Access Not Granted")
                    }
                }
            })
        } else if eventCenter.calendarAccessGranted() {
            calendarGrantButton.title = "Granted".localized()
        } else {
            calendarGrantButton.title = "Denied".localized()
        }
    }

    @IBAction func remindersAction(_: NSButton) {
        let eventCenter = EventCenter.sharedCenter()

        if eventCenter.reminderAccessNotDetermined() {
            reminderActivityIndicator.startAnimation(nil)

            eventCenter.requestAccess(to: .reminder, completionHandler: { granted in

                OperationQueue.main.addOperation {
                    self.reminderActivityIndicator.stopAnimation(nil)
                }

                if granted {
                    OperationQueue.main.addOperation {
                        self.view.window?.orderBack(nil)
                        NSApp.activate(ignoringOtherApps: true)

                        self.reminderGrantButton.title = "Granted".localized()
                    }
                } else {
                    Logger.log(object: ["Reminder Access Not Granted": "YES"], for: "Reminder Access Not Granted")
                }
            })
        } else if eventCenter.reminderAccessGranted() {
            reminderGrantButton.title = "Granted".localized()
        } else {
            reminderGrantButton.title = "Denied".localized()
        }
    }
}
