// Copyright © 2015 Abhishek Banthia

import Cocoa

class FinalOnboardingViewController: NSViewController {
    @IBOutlet var titleLabel: NSTextField!
    @IBOutlet var subtitleLabel: NSTextField!
    @IBOutlet var accesoryLabel: NSTextField!
    @IBOutlet var accessoryImageView: NSImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.stringValue = "You're all set!"
        subtitleLabel.stringValue = "Thank you for the details."
        accesoryLabel.stringValue = "You'll see a clock icon in your Menu Bar when you launch the app. If you'd like to see a dock icon, go to Preferences."
        accessoryImageView.image = Themer.shared().menubarOnboardingImage()
    }
}
