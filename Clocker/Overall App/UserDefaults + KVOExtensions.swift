// Copyright © 2015 Abhishek Banthia

import Cocoa

extension UserDefaults {

    @objc dynamic var displayFutureSlider: Int {
        return integer(forKey: CLDisplayFutureSliderKey)
    }

    @objc dynamic var userFontSize: Int {
        return integer(forKey: CLUserFontSizePreference)
    }

    @objc dynamic var sliderDayRange: Int {
        return integer(forKey: CLFutureSliderRange)
    }
}
