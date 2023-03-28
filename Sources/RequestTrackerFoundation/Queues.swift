//
//  Queues.swift
//  
//  Functions related to queues
//  Created by Chris on 12/7/22.
//

import Foundation
import FoundationNetworking


/**
 Provides errors that can be thrown by ticket-related functions
 */
enum QueueError : Error {
    case FailedToDecodeServerResponse, InvalidResponseFromServer
}

/**
 An extension for `TicketError` that provides error descriptions

 */
extension QueueError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .FailedToDecodeServerResponse: return "The data returned from the server does not fit the expected schema"
        case .InvalidResponseFromServer: return "The response returned from the server did not contain the JSON keys usually included in this type of response"
        }
    }
}

/**
 An extension for RequestTrackerFoundation that provides functionality for interacting with queues
 */
extension RequestTrackerFoundation {
    
    /**
     Gets limited information of all queues that are visible to the current user.
     - Returns: An `Array` of `RTObject`s that represents all visible queues. Pass to `getQueues()` for detailed queue information
     */
    public func getQueueRefs() async throws -> [RTObject] {
        if self.httpClient == nil {
            throw RequestTrackerFoundationError.RequestTrackerFoundationNotInitialized
        }
        let endpoint = Endpoint(httpClient: self.httpClient!, host: self.rtServerHost, path: "/queues/all", authenticationType: self.authenticationType, credentials: self.credentials, method: .GET, fields: "Name")
        let response = try await endpoint.makeRequest()
        let data = try await response.body.collect(upTo: 1024 * 1024 * 100) // 100MB
        let json = try JSONSerialization.jsonObject(with: data) as? [String : Any]
        if keysExist(dict: json!, keysToCheck: ["page", "total", "pages", "count", "per_page", "items"]) {
            let queues = try await fetchAndMergePaginatedData(firstPage: json!, httpClient: self.httpClient!, host: self.rtServerHost, authenticationType: authenticationType, credentials: credentials)
            if queues.count == 0 {
                return []
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
                        throw QueueError.FailedToDecodeServerResponse
                    }
                }
                return returnQueues
            }
        }
        else {
            throw QueueError.InvalidResponseFromServer
        }
    }
    
    // queues can be output from getQueueRefs. This gets more detailed info about each queue
    /**
     Gets detailed information of all queues that are visible to the current user.
     - Parameters:
        - queues: An array of `RTObject`s that should represent queues
     - Returns: An `Array` of `Queue`s that represents all visible queues
     */
    public func getQueues(queues: [RTObject]) async throws -> [Queue] {
        if self.httpClient == nil {
            throw RequestTrackerFoundationError.RequestTrackerFoundationNotInitialized
        }
        var detailedQueues = [Queue]()
        for rtobject in queues {
            let endpoint = Endpoint(httpClient: self.httpClient!, url: rtobject._url, authenticationType: self.authenticationType, credentials: self.credentials, method: .GET)
            let response = try await endpoint.makeRequest()
            let data = try await response.body.collect(upTo: 1024 * 1024 * 100) // 100MB
            let json = try JSONSerialization.jsonObject(with: data)
            let queue = try JSONDecoder().decode(Queue.self, from: JSONSerialization.data(withJSONObject: json))
            detailedQueues.append(queue)
        }
        return detailedQueues
    }
    
    public func getMemberTicketStats(queue: Queue) async throws -> [String:Int] {
        if self.httpClient == nil {
            throw RequestTrackerFoundationError.RequestTrackerFoundationNotInitialized
        }
        let newResponse = try await search(query: "Queue = '\(queue.Name)' AND Status = '__Active__'", fields: "Status")
        var tickets: [Ticket] = []
        for ref in newResponse {
            try await tickets.append(self.getTicketInfo(ticketRef: ref))
        }
        var openCount = 0
        var newCount = 0
        var stalledCount = 0
        
        for ticket in tickets {
            if ticket.Status == "new" {
                newCount += 1
            }
            else if ticket.Status == "open" {
                openCount += 1
            }
            else if ticket.Status == "stalled" {
                stalledCount += 1
            }
        }
        
        return [
            "numOpen" : openCount,
            "numNew" : newCount,
            "numStalled" : stalledCount
        ]
    }
}
