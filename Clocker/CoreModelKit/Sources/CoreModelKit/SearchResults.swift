// Copyright © 2015 Abhishek Banthia

import Cocoa

public enum ResultStatus {
    public static let okay = "OK"
    public static let zeroResults = "ZERO_RESULTS"
    public static let requestDenied = "REQUEST_DENIED"
}

public struct SearchResult: Codable {
    public let results: [Result]
    public let status: String
    public let errorMessage: String?

    public struct Result: Codable {
        public let addressComponents: [AddressComponent]
        public let formattedAddress: String
        public let geometry: Geometry
        public let placeId: String
        public let types: [String]

        private enum CodingKeys: String, CodingKey {
            case addressComponents = "address_components"
            case formattedAddress = "formatted_address"
            case geometry
            case placeId = "place_id"
            case types
        }
    }

    public struct Geometry: Codable {
        public let location: Location
        public let locationType: String

        public struct Location: Codable {
            public let lat: Double
            public let lng: Double
        }

        private enum CodingKeys: String, CodingKey {
            case locationType = "location_type"
            case location
        }
    }

    public struct AddressComponent: Codable {
        public let longName: String
        public let shortName: String
        public let types: [String]

        private enum CodingKeys: String, CodingKey {
            case longName = "long_name"
            case shortName = "short_name"
            case types
        }
    }

    private enum CodingKeys: String, CodingKey {
        case results
        case status
        case errorMessage = "error_message"
    }
}

public struct Timezone: Codable {
    public let dstOffset: Int
    public let rawOffset: Int
    public let status: String
    public let timeZoneId: String
    public let timeZoneName: String
}
