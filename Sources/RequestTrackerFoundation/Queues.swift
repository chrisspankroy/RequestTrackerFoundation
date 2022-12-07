//
//  Queues.swift
//  
//  Functions related to queues
//  Created by Chris on 12/7/22.
//

import Foundation

extension RequestTrackerFoundation {
    
    // Gets all queues that the user has access to see
    public func getAllQueues() async throws -> [RTObject]? {
        if self.urlSession == nil {
            throw RequestTrackerFoundationError.RequestTrackerFoundationNotInitialized
        }
        var endpoint = Endpoint(urlSession: self.urlSession!, host: self.rtServerHost, path: "/queues/all", authenticationType: self.authenticationType, credentials: self.credentials)
        try await endpoint.makeRequest()
        var json = try JSONSerialization.jsonObject(with: endpoint.responseData!) as? [String : Any]
        if keysExist(dict: json!, keysToCheck: ["page", "total", "pages", "count", "per_page", "items"]) {
            var queues = try await fetchAndMergePaginatedData(firstPage: json!, urlSession: self.urlSession!, host: self.rtServerHost, authenticationType: authenticationType, credentials: credentials)
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
    public func getQueues(queues: [RTObject]) async throws -> [Queue]? {
        if self.urlSession == nil {
            throw RequestTrackerFoundationError.RequestTrackerFoundationNotInitialized
        }
        var detailedQueues = [Queue]()
        for rtobject in queues {
            var endpoint = Endpoint(urlSession: self.urlSession!, url: rtobject._url, authenticationType: self.authenticationType, credentials: self.credentials)
            try await endpoint.makeRequest()
            var json = try JSONSerialization.jsonObject(with: endpoint.responseData!) as? [String : Any]
            var idk = json as? [String:Any]
            let queue = try JSONDecoder().decode(Queue.self, from: JSONSerialization.data(withJSONObject: idk))
            detailedQueues.append(queue)
        }
        return detailedQueues
    }
}
