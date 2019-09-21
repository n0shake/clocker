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
        appName.stringValue = "Launch at Login".localized()
        onboardingType.stringValue = "This can be configured later in Clocker Preferences.".localized()

        // स्टार्टअप पर स्वचालित रूप से ऐप खोलना चाहिए
        accessoryLabel.stringValue = "Should Clocker open automatically on startup?".localized()
        privacyLabel.stringValue = " "

        [privacyLabel, accessoryLabel, onboardingType, appName].forEach { $0?.textColor = Themer.shared().mainTextColor() }
    }
}
