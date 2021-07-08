// Copyright © 2015 Abhishek Banthia

import Cocoa

class NetworkManager: NSObject {
    static let parsingError: NSError = {
        let userInfoDictionary: [String: Any] = [NSLocalizedDescriptionKey: "Parsing Error"]
        let error = NSError(domain: "APIError", code: 102, userInfo: userInfoDictionary)
        return error
    }()

    static let internalServerError: NSError = {
        let localizedError = """
        There was a problem retrieving your information. Please try again later.
        If the problem continues please contact App Support.
        """
        let userInfoDictionary: [String: Any] = [NSLocalizedDescriptionKey: "Internal Error",
                                                 NSLocalizedFailureReasonErrorKey: localizedError]
        let error = NSError(domain: "APIError", code: 100, userInfo: userInfoDictionary)
        return error
    }()

    static let unableToGenerateURL: NSError = {
        let localizedError = """
        There was a problem searching the location. Please try again later.
        If the problem continues please contact App Support.
        """
        let userInfoDictionary: [String: Any] = [NSLocalizedDescriptionKey: "Unable to generate URL",
                                                 NSLocalizedFailureReasonErrorKey: localizedError]
        let error = NSError(domain: "APIError", code: 100, userInfo: userInfoDictionary)
        return error
    }()
}

extension NetworkManager {
    @discardableResult
    class func task(with path: String, completionHandler: @escaping (_ response: Data?, _ error: NSError?) -> Void) -> URLSessionDataTask? {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 20

        let session = URLSession(configuration: configuration)

        guard let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encodedPath)
        else {
            completionHandler(nil, unableToGenerateURL)
            return nil
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let dataTask = session.dataTask(with: request) { data, urlResponse, error in

            // Check if we're running a network UI test
            if ProcessInfo.processInfo.arguments.contains("mockTimezoneDown") {
                completionHandler(nil, internalServerError)
                return
            }

            guard error == nil, let httpURLResponse = urlResponse as? HTTPURLResponse, let json = data else {
                completionHandler(nil, internalServerError)
                return
            }

            if httpURLResponse.statusCode != 200 {
                completionHandler(nil, internalServerError)
                return
            }

            completionHandler(json, nil)
        }

        dataTask.resume()

        return dataTask
    }

    class func isConnected() -> Bool {
        // For tests
        if ProcessInfo.processInfo.arguments.contains("mockNetworkDown") {
            return false
        }

        let status = Reach().connectionStatus()
        switch status {
        case .online(.wwan):
            return true
        case .online(.wiFi):
            return true
        default:
            return false
        }
    }
}
