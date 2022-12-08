//
//  Tickets.swift
//  
//  Functions related to tickets
//  Created by Chris on 12/7/22.
//

import Foundation

/**
 Provides errors that can be thrown by ticket-related functions
 */
enum TicketError : Error {
    case InvalidTicketRef, FailedToGetTicketInfo, PreconditionFailed, FailedToUpdateTicket
}

/**
 An extension for `TicketError` that provides error descriptions

 */
extension TicketError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .InvalidTicketRef: return "The passed ticketRef does not represent a ticket"
        case .FailedToGetTicketInfo: return "The server returned a non-200 status code when requesting ticket information"
        case .PreconditionFailed: return "The server rejected the provided ETag. This means the resource has been updated since it was fetched."
        case .FailedToUpdateTicket: return "Unable to update ticket. See console for more information"
        }
    }
}

/**
 An extension for RequestTrackerFoundation that provides functionality for interacting with tickets
 */
extension RequestTrackerFoundation {
    /**
     Creates a new ticket
     
     - Parameters:
        - queue: The `Queue` to create the ticket in
        - ticketFields: A dictionary representing the fields the ticket should contain
     - Returns: A `RTObject` representing the newly-created ticket
     */
    public func createTicket(queue: Queue, ticketFields: [String:Any]) async throws -> RTObject? {
        for hyperlink in queue._hyperlinks {
            if hyperlink.ref == "create" {
                // This is the hyperlink we should use
                do {
                    var data = try JSONSerialization.data(withJSONObject: ticketFields)
                    let endpoint = Endpoint(urlSession: self.urlSession!, url: hyperlink._url, authenticationType: self.authenticationType, credentials: self.credentials, method: .POST, bodyData: data, bodyContentType: "application/json")
                    try await endpoint.makeRequest()
                    if endpoint.response?.statusCode == 201 {
                        do {
                            let json = try JSONSerialization.jsonObject(with: endpoint.responseData!)
                            var rtObject = try JSONDecoder().decode(RTObject.self, from: JSONSerialization.data(withJSONObject: json))
                            return rtObject
                        }
                        catch {
                            throw RequestTrackerFoundationError.FailedToDecodeJSON
                        }
                    }
                    else {
                        print("Failed to create ticket. Dumping response from server")
                        print("Response: \(endpoint.response)")
                        print("Response Data: \(String(data: endpoint.responseData!, encoding: .utf8))")
                        throw RequestTrackerFoundationError.FailedToCreateTicket
                    }
                }
                catch {
                    throw RequestTrackerFoundationError.FailedToEncodeJSON
                }
            }
        }
        // If you got here then there is no create hyperlink in the provided queue (do you have ticket create perms in this queue?)
        return nil
    }
    
    /**
     Updates an existing ticket
     - Parameters:
        - ticket: The `Ticket` to update
        - ticketFields: A dictionary of fields to update
     - Returns: An `Array` of `String`s describing the updates that were made
     */
    public func updateTicket(ticket: Ticket, ticketFields: [String:Any]) async throws -> [String]? {
        for hyperlink in ticket._hyperlinks {
            if hyperlink.ref == "self" {
                // This is the hyperlink we should use
                do {
                    var data = try JSONSerialization.data(withJSONObject: ticketFields)
                    let endpoint = Endpoint(urlSession: self.urlSession!, url: hyperlink._url, authenticationType: self.authenticationType, credentials: self.credentials, method: .PUT, bodyData: data, bodyContentType: "application/json", etag: ticket.etag)
                    try await endpoint.makeRequest()
                    if endpoint.response?.statusCode == 412 {
                        // Invalid ETag
                        throw TicketError.PreconditionFailed
                    }
                    else if endpoint.response?.statusCode == 200 {
                        do {
                            let json = try JSONSerialization.jsonObject(with: endpoint.responseData!)
                            var answerArr = try JSONDecoder().decode([String].self, from: JSONSerialization.data(withJSONObject: json))
                            return answerArr
                        }
                        catch {
                            throw RequestTrackerFoundationError.FailedToDecodeJSON
                        }
                    }
                    else {
                        print("Failed to update ticket. Dumping response from server")
                        print("Response: \(endpoint.response)")
                        print("Response Data: \(String(data: endpoint.responseData!, encoding: .utf8))")
                        throw TicketError.FailedToUpdateTicket
                    }
                }
                catch {
                    throw RequestTrackerFoundationError.FailedToEncodeJSON
                }
            }
        }
        // If you got here then there is no self hyperlink in the provided queue (do you have read perms in this queue?)
        return nil
    }
    
    
    
    /**
     Gets the information of a ticket
     - Parameters:
        - ticketRef: A `RTObject`  representing the ticket
     - Returns:
        - A `Ticket` representing the ticket
     */
    public func getTicketInfo(ticketRef: RTObject) async throws -> Ticket {
        if ticketRef.type != "ticket" {
            throw TicketError.InvalidTicketRef
        }
        var endpoint = Endpoint(urlSession: self.urlSession!, url: ticketRef._url, authenticationType: self.authenticationType, credentials: self.credentials, method: .GET)
        try await endpoint.makeRequest()
        if endpoint.response?.statusCode == 200 {
            let json = try JSONSerialization.jsonObject(with: endpoint.responseData!)
            var ticket = try JSONDecoder().decode(Ticket.self, from: JSONSerialization.data(withJSONObject: json))
            ticket.etag = endpoint.response?.value(forHTTPHeaderField: "ETag")?.replacingOccurrences(of: "\"", with: "")
            return ticket
        }
        else {
            throw TicketError.FailedToGetTicketInfo
        }
    }
    
    /**
     Gets the information of a ticket
     - Parameters:
        - id: The numeric ID of the ticket
     - Returns:
        - A `Ticket` representing the ticket
     */
    public func getTicketInfo(id: Int) async throws -> Ticket {
        let endpoint = Endpoint(urlSession: self.urlSession!, host: self.rtServerHost, path: "/ticket/\(id)", authenticationType: self.authenticationType, credentials: self.credentials, method: .GET)
        try await endpoint.makeRequest()
        if endpoint.response?.statusCode == 200 {
            let json = try JSONSerialization.jsonObject(with: endpoint.responseData!)
            var ticket = try JSONDecoder().decode(Ticket.self, from: JSONSerialization.data(withJSONObject: json))
            ticket.etag = endpoint.response?.value(forHTTPHeaderField: "ETag")?.replacingOccurrences(of: "\"", with: "")
            return ticket
        }
        else {
            throw TicketError.FailedToGetTicketInfo
        }
    }
}
