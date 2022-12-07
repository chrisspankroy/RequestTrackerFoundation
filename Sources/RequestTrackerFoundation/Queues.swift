//
//  Queues.swift
//  
//  Functions related to queues
//  Created by Chris on 12/7/22.
//

import Foundation

/**
 An extension for RequestTrackerFoundation that provides functionality for interacting with queues
 */
extension RequestTrackerFoundation {
    
    /**
     Gets limited information of all queues that are visible to the current user.
     - Returns: An `Array` of `RTObject`s that represents all visible queues. Pass to `getQueues()` for detailed queue information
     */
    public func getAllQueues() async throws -> [RTObject]? {
        if self.urlSession == nil {
            throw RequestTrackerFoundationError.RequestTrackerFoundationNotInitialized
        }
        let endpoint = Endpoint(urlSession: self.urlSession!, host: self.rtServerHost, path: "/queues/all", authenticationType: self.authenticationType, credentials: self.credentials)
        try await endpoint.makeRequest()
        let json = try JSONSerialization.jsonObject(with: endpoint.responseData!) as? [String : Any]
        if keysExist(dict: json!, keysToCheck: ["page", "total", "pages", "count", "per_page", "items"]) {
            let queues = try await fetchAndMergePaginatedData(firstPage: json!, urlSession: self.urlSession!, host: self.rtServerHost, authenticationType: authenticationType, credentials: credentials)
            if queues.count == 0 {
                return nil
            }
            else {
                // Parse into array of Queue objects and return
                var returnQueues = Array<RTObject>()
                for queueData in queues {
                    do {
                        let queue = try JSONDecoder().decode(RTObject.self, from: JSONSerialization.data(withJSONObject: queueData))
                        returnQueues.append(queue)
                    }
                    catch {
                        print(error)
                        throw RequestTrackerFoundationError.FailedToDecodeJSON
                    }
                }
                return returnQueues
            }
        }
        else {
            throw RequestTrackerFoundationError.InvalidResponseFromServer
        }
    }
    
    // queues can be output from getAllQueues. This gets more detailed info about each queue
    /**
     Gets detailed information of all queues that are visible to the current user.
     - Parameters:
        - queues: An array of `RTObject`s that should represent queues
     - Returns: An `Array` of `Queue`s that represents all visible queues
     */
    public func getQueues(queues: [RTObject]) async throws -> [Queue]? {
        if self.urlSession == nil {
            throw RequestTrackerFoundationError.RequestTrackerFoundationNotInitialized
        }
        var detailedQueues = [Queue]()
        for rtobject in queues {
            let endpoint = Endpoint(urlSession: self.urlSession!, url: rtobject._url, authenticationType: self.authenticationType, credentials: self.credentials)
            try await endpoint.makeRequest()
            let json = try JSONSerialization.jsonObject(with: endpoint.responseData!)
            let queue = try JSONDecoder().decode(Queue.self, from: JSONSerialization.data(withJSONObject: json))
            detailedQueues.append(queue)
        }
        return detailedQueues
    }
}
