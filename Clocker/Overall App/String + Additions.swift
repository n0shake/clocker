// Copyright © 2015 Abhishek Banthia

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
}
