// Copyright © 2015–2026 Adrak Studio LLC

import Cocoa

extension String {
    func filteredName() -> String {
        var filteredAddress = self

        let commaSeperatedComponents = components(separatedBy: ",")

        if let first = commaSeperatedComponents.first {
            filteredAddress = first
        }

        return filteredAddress
    }

    func localized() -> String {
        return NSLocalizedString(self, comment: "Title for \(self)")
    }
}
