//
//  File.swift
//  
//
//  Created by Chris on 1/16/23.
//

import Foundation

enum UserError : Error {
    case FailedToDecodeServerResponse
}

/**
 An extension for `TicketError` that provides error descriptions

 */
extension UserError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .FailedToDecodeServerResponse: return "The data returned from the server does not fit the expected schema"
        }
    }
}

extension RequestTrackerFoundation {
    func getUsers() async throws -> [User] {
        let endpoint = Endpoint(urlSession: self.urlSession!, host: self.rtServerHost, path: "/users", authenticationType: self.authenticationType, credentials: self.credentials, method: .GET, fields: "RealName,id,Name")
        let (data, response) = try await endpoint.makeRequest()
        if response.statusCode == 200 {
            let json = try JSONSerialization.jsonObject(with: data) as? [String : Any]
            let mergedPaginatedData = try await fetchAndMergePaginatedData(firstPage: json!, urlSession: self.urlSession!, host: self.rtServerHost, authenticationType: self.authenticationType, credentials: self.credentials)
            var returnArr : [User] = []
            for entry in mergedPaginatedData {
                var castedEntry = try JSONDecoder().decode(User.self, from: JSONSerialization.data(withJSONObject: entry))
                // need to implement
                //castedEntry.localizeDates()
                returnArr.append(castedEntry)
            }
            return returnArr
        }
        else {
            throw TicketError.FailedToDecodeServerResponse
        }
    }
}