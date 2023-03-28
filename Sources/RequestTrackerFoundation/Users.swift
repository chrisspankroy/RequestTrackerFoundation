//
//  File.swift
//  
//
//  Created by Chris on 1/16/23.
//

import Foundation
import FoundationNetworking

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
    // This can be very very slow if there are many users
    func getUsers() async throws -> [User] {
        let endpoint = Endpoint(httpClient: self.httpClient!, host: self.rtServerHost, path: "/users", authenticationType: self.authenticationType, credentials: self.credentials, method: .GET, fields: "RealName,id,Name")
        let response = try await endpoint.makeRequest()
        let data = try await response.body.collect(upTo: 1024 * 1024 * 100) // 100MB
        if response.status.code == 200 {
            let json = try JSONSerialization.jsonObject(with: data) as? [String : Any]
            let mergedPaginatedData = try await fetchAndMergePaginatedData(firstPage: json!, httpClient: self.httpClient!, host: self.rtServerHost, authenticationType: self.authenticationType, credentials: self.credentials)
            var returnArr : [User] = []
            for entry in mergedPaginatedData {
                let castedEntry = try JSONDecoder().decode(User.self, from: JSONSerialization.data(withJSONObject: entry))
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
