// Copyright © 2015 Abhishek Banthia

import Cocoa

public struct SearchResult: Codable {
    let results: [Result]
    let status: String

    public struct Result: Codable {
        let addressComponents: [AddressComponent]
        let formattedAddress: String
        let geometry: Geometry
        let placeId: String
        let types: [String]

        private enum CodingKeys: String, CodingKey {
            case addressComponents = "address_components"
            case formattedAddress = "formatted_address"
            case geometry
            case placeId = "place_id"
            case types
        }
    }

    public struct Geometry: Codable {
        let location: Location
        let locationType: String

        public struct Location: Codable {
            let lat: Double
            let lng: Double
        }

        private enum CodingKeys: String, CodingKey {
            case locationType = "location_type"
            case location
        }
    }

    public struct AddressComponent: Codable {
        let longName: String
        let shortName: String
        let types: [String]

        private enum CodingKeys: String, CodingKey {
            case longName = "long_name"
            case shortName = "short_name"
            case types
        }
    }
}

public struct Timezone: Codable {
    let dstOffset: Int
    let rawOffset: Int
    let status: String
    let timeZoneId: String
    let timeZoneName: String
}
