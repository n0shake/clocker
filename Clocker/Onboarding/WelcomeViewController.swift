// Copyright © 2015 Abhishek Banthia

import Cocoa

class WelcomeViewController: NSViewController {
    @IBOutlet var appLabel: NSTextField!
    @IBOutlet var accessoryLabel: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    private func setup() {
        appLabel.stringValue = "Clocker"
        accessoryLabel.stringValue = "It only takes 3 steps to set up Clocker."

        [appLabel, accessoryLabel].forEach { $0?.textColor = Themer.shared().mainTextColor() }
    }
}
