// Copyright © 2015 Abhishek Banthia

import Cocoa
import Firebase

extension NSNib.Name {
    static let appFeedbackWindowIdentifier = NSNib.Name("AppFeedbackWindow")
    static let onboardingWindowIdentifier = NSNib.Name("OnboardingWindow")
    static let welcomeViewIdentifier = NSNib.Name("WelcomeView")
    static let startAtLoginViewIdentifier = NSNib.Name("StartAtLoginView")
}

struct AppFeedbackConstants {
    static let CLAppFeedbackNibIdentifier = "AppFeedbackWindow"
    static let CLAppFeedbackNoResponseString = "Not Provided"
    static let CLAppFeedbackNameProperty = "name"
    static let CLAppFeedbackEmailProperty = "email"
    static let CLAppFeedbackFeedbackProperty = "feedback"
    static let CLOperatingSystemVersion = "OS"
    static let CLClockerVersion = "Clocker version"
    static let CLFeedbackAlertTitle = "Thank you for helping make Clocker even better!"
    static let CLFeedbackAlertInformativeText = "We owe you a candy. 😇"
    static let CLFeedbackAlertButtonTitle = "Close"
    static let CLFeedbackNotEnteredErrorMessage = "Please enter some feedback."
}

class AppFeedbackWindowController: NSWindowController {
    @IBOutlet var nameField: NSTextField!
    @IBOutlet var emailField: NSTextField!
    @IBOutlet var feedbackTextView: NSTextView!
    @IBOutlet var informativeText: NSTextField!
    @IBOutlet var progressIndicator: NSProgressIndicator!

    private var serialNumber: String? {
        let platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"))

        guard platformExpert > 0 else {
            return nil
        }

        guard let serialNumber = (IORegistryEntryCreateCFProperty(platformExpert, kIOPlatformSerialNumberKey as CFString, kCFAllocatorDefault, 0).takeUnretainedValue() as? String) else {
            return nil
        }

        IOObjectRelease(platformExpert)

        return serialNumber
    }

    private var isActivityInProgress = false {
        didSet {
            progressIndicator.isHidden = !isActivityInProgress
            isActivityInProgress ? progressIndicator.startAnimation(nil) : progressIndicator.stopAnimation(nil)
        }
    }

    static var sharedWindow: AppFeedbackWindowController = AppFeedbackWindowController(windowNibName: NSNib.Name.appFeedbackWindowIdentifier)

    override func windowDidLoad() {
        super.windowDidLoad()

        window?.backgroundColor = Themer.shared().mainBackgroundColor()
        window?.titleVisibility = .hidden
        window?.titlebarAppearsTransparent = true

        progressIndicator.isHidden = true
        informativeText.setAccessibilityIdentifier("InformativeText")
        feedbackTextView.setAccessibilityIdentifier("FeedbackTextView")
        nameField.setAccessibilityIdentifier("NameField")
        emailField.setAccessibilityIdentifier("EmailField")
        progressIndicator.setAccessibilityIdentifier("ProgressIndicator")

        setup()

        NotificationCenter.default.addObserver(forName: .themeDidChangeNotification, object: nil, queue: OperationQueue.main) { _ in
            self.window?.backgroundColor = Themer.shared().mainBackgroundColor()
            self.setup()
        }
    }

    @objc class func shared() -> AppFeedbackWindowController {
        return sharedWindow
    }

    override init(window: NSWindow!) {
        super.init(window: window)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @IBAction func sendFeedback(_: Any) {
        resetInformativeLabel()

        isActivityInProgress = true

        if didUserEnterFeedback() == false {
            return
        }

        let feedbackInfo = retrieveDataForSending()
        sendDataToFirebase(feedbackInfo: feedbackInfo)
        showSucccessOnSendingInfo()
    }

    @IBAction func cancel(_: Any) {
        window?.close()
    }

    private func didUserEnterFeedback() -> Bool {
        let cleanedUpString = feedbackTextView.string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

        if cleanedUpString.isEmpty {
            informativeText.stringValue = AppFeedbackConstants.CLFeedbackNotEnteredErrorMessage

            Timer.scheduledTimer(withTimeInterval: 5.0,
                                 repeats: false,
                                 block: { _ in
                                     self.resetInformativeLabel()
            })

            isActivityInProgress = false

            return false
        }

        return true
    }

    private func retrieveDataForSending() -> [String: String] {
        guard let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
            let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String else {
            return [:]
        }

        let name = nameField.stringValue.isEmpty ? AppFeedbackConstants.CLAppFeedbackNoResponseString : nameField.stringValue
        let email = emailField.stringValue.isEmpty ? AppFeedbackConstants.CLAppFeedbackNoResponseString : emailField.stringValue
        let appFeedbackProperty = feedbackTextView.string
        let operatingSystem = ProcessInfo.processInfo.operatingSystemVersion
        let osVersion = "\(operatingSystem.majorVersion).\(operatingSystem.minorVersion).\(operatingSystem.patchVersion)"
        let versionInfo = "Clocker \(shortVersion) (\(appVersion))"

        let feedbackInfo = [
            AppFeedbackConstants.CLAppFeedbackNameProperty: name,
            AppFeedbackConstants.CLAppFeedbackEmailProperty: email,
            AppFeedbackConstants.CLAppFeedbackFeedbackProperty: appFeedbackProperty,
            AppFeedbackConstants.CLOperatingSystemVersion: osVersion,
            AppFeedbackConstants.CLClockerVersion: versionInfo
        ]

        return feedbackInfo
    }

    private func sendDataToFirebase(feedbackInfo: [String: String]) {
        guard let identifier = serialNumber else {
            assertionFailure("Serial Identifier was unexpectedly nil")
            return
        }

        let myRootReference = Firebase(url: "https://fiery-heat-5237.firebaseio.com/Feedback")
        let feedbackReference = myRootReference?.child(byAppendingPath: identifier)
        feedbackReference?.setValue(feedbackInfo)
    }

    private func showSucccessOnSendingInfo() {
        guard let feedbackWindow = window else {
            assertionFailure("Window property was unexpectedly nil")
            return
        }

        isActivityInProgress = false

        let alert = NSAlert()
        alert.messageText = "Thank you for helping make Clocker even better!"
        alert.informativeText = AppFeedbackConstants.CLFeedbackAlertInformativeText
        alert.addButton(withTitle: AppFeedbackConstants.CLFeedbackAlertButtonTitle)
        alert.beginSheetModal(for: feedbackWindow) { _ in
            self.window?.close()
        }
    }

    private func resetInformativeLabel() {
        informativeText.stringValue = CLEmptyString
    }

    @IBOutlet var headerLabel: NSTextField!
    @IBOutlet var contactBox: NSBox!
    @IBOutlet var accessoryInfo: NSTextField!

    private func setup() {
        headerLabel.stringValue = "Tell us what you think!"
        contactBox.title = "Contact Information (Optional)"
        accessoryInfo.stringValue = "Contact fields are optional! Your contact information will let us contact you in case we need more information or can help!"

        [headerLabel, accessoryInfo].forEach { $0?.textColor = Themer.shared().mainTextColor() }

        contactBox.borderColor = Themer.shared().mainTextColor()
    }
}

extension AppFeedbackWindowController: NSWindowDelegate {
    func windowWillClose(_: Notification) {
        resetInformativeLabel()
        performClosingCleanUp()
        bringPreferencesWindowToFront()
    }

    func performClosingCleanUp() {
        nameField.stringValue = CLEmptyString
        emailField.stringValue = CLEmptyString
        feedbackTextView.string = CLEmptyString
        isActivityInProgress = false
    }

    func bringPreferencesWindowToFront() {
        let oneWindowController = OneWindowController.shared()
        oneWindowController.window?.makeKeyAndOrderFront(self)
        NSApp.activate(ignoringOtherApps: true)
    }
}
