// Copyright © 2015 Abhishek Banthia

import Cocoa

class OnboardingWelcomeViewController: NSViewController {
    @IBOutlet var appLabel: NSTextField!
    @IBOutlet var accessoryLabel: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    private func setup() {
        appLabel.stringValue = NSLocalizedString("CFBundleDisplayName",
                                                 comment: "App Name")
        accessoryLabel.stringValue = NSLocalizedString("It only takes 3 steps to set up Clocker.",
                                                       comment: "App Setup Description")

        [appLabel, accessoryLabel].forEach { $0?.textColor = Themer.shared().mainTextColor() }
    }
}
