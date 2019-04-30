// Copyright © 2015 Abhishek Banthia

import Cocoa

class StartAtLoginViewController: NSViewController {
    @IBOutlet var appName: NSTextField!
    @IBOutlet var onboardingType: NSTextField!
    @IBOutlet var accessoryLabel: NSTextField!
    @IBOutlet var privacyLabel: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    private func setup() {
        appName.stringValue = "Launch at Login"
        onboardingType.stringValue = "This can be configured later in Clocker Preferences."

        accessoryLabel.stringValue = "Should Clocker open automatically on startup?"
        privacyLabel.stringValue = " "

        [privacyLabel, accessoryLabel, onboardingType, appName].forEach { $0?.textColor = Themer.shared().mainTextColor() }
    }
}
