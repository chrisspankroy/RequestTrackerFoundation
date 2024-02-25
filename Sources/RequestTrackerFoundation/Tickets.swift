//
//  Tickets.swift
//  
//  Functions related to tickets
//  Created by Chris on 12/7/22.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/**
 Provides errors that can be thrown by ticket-related functions
 */
enum TicketError : Error {
    case InvalidTicketRef, FailedToGetTicketInfo, PreconditionFailed, FailedToUpdateTicket, FailedToReplyToTicket, PermissionError, FailedToCreateTicket, FailedToDecodeServerResponse, FailedToCommentOnTicket, SearchError
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
        case .FailedToUpdateTicket: return "Unable to update ticket"
        case .FailedToReplyToTicket: return "Unable to reply to ticket"
        case .PermissionError: return "No hyperlink was found for the requested operation. Do you have permissions to make this operation?"
        case .FailedToCreateTicket: return "The server's response indicated non-success while creating the ticket"
        case .FailedToDecodeServerResponse: return "The data returned from the server does not fit the expected schema"
        case .FailedToCommentOnTicket: return "Unable to comment on ticket"
        case .SearchError: return "Unable to properly encode search query"
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
    public func createTicket(queue: Queue, ticketFields: [String:Any]) async throws -> RTObject {
        for hyperlink in queue._hyperlinks {
            if hyperlink.ref == "create" {
                // This is the hyperlink we should use
                let jsonData = try JSONSerialization.data(withJSONObject: ticketFields)
                let endpoint = Endpoint(httpClient: self.httpClient!, url: hyperlink._url, authenticationType: self.authenticationType, credentials: self.credentials, method: .POST, bodyData: jsonData, bodyContentType: "application/json")
                let response = try await endpoint.makeRequest()
                let data = try await response.body.collect(upTo: 1024 * 1024 * 100) // 100MB
                if response.status.code == 201 {
                    do {
                        let json = try JSONSerialization.jsonObject(with: data)
                        let rtObject = try JSONDecoder().decode(RTObject.self, from: JSONSerialization.data(withJSONObject: json))
                        return rtObject
                    }
                    catch {
                        throw TicketError.FailedToDecodeServerResponse
                    }
                }
                else {
                    throw TicketError.FailedToCreateTicket
                }
            }
        }
        // If you got here then there is no create hyperlink in the provided queue (do you have ticket create perms in this queue?)
        throw TicketError.PermissionError
    }
    
    /**
     Updates an existing ticket
     - Parameters:
        - ticket: The `Ticket` to update. The 'inout' keyword passes parameter by reference instead of by value so we can update the etag from here
        - ticketFields: A dictionary of fields to update
     - Returns: An `Array` of `String`s describing the updates that were made
     */
    public func updateTicket(ticket: inout Ticket, ticketFields: [String:Any]) async throws -> [String] {
        for hyperlink in ticket._hyperlinks {
            if hyperlink.ref == "self" {
                // This is the hyperlink we should use
                let jsonData = try JSONSerialization.data(withJSONObject: ticketFields)
                let endpoint = Endpoint(httpClient: self.httpClient!, url: hyperlink._url, authenticationType: self.authenticationType, credentials: self.credentials, method: .PUT, bodyData: jsonData, bodyContentType: "application/json", etag: ticket.etag)
                let response = try await endpoint.makeRequest()
                let data = try await response.body.collect(upTo: 1024 * 1024 * 100) // 100MB
                if response.status.code == 412 {
                    // Invalid ETag
                    throw TicketError.PreconditionFailed
                }
                else if response.status.code == 200 {
                    do {
                        let json = try JSONSerialization.jsonObject(with: data)
                        let answerArr = try JSONDecoder().decode([String].self, from: JSONSerialization.data(withJSONObject: json))
                        
                        // Update etag before returning
                        let newEtag = try await self.getTicketInfo(id: ticket.id).etag
                        ticket.etag = newEtag

                        return answerArr
                    }
                    catch {
                        throw TicketError.FailedToDecodeServerResponse
                    }
                }
                else {
                    throw TicketError.FailedToUpdateTicket
                }
            }
        }
        // If you got here then there is no self hyperlink in the provided queue (do you have read perms in this queue?)
        throw TicketError.PermissionError
    }
    
    /**
     Posts a reply to an existing ticket. Attachment content must be MIME base64 encoded
     - Parameters:
        - ticket: The `Ticket` to update
        - ticketFields: A dictionary of properties to post to the ticket
     - Returns: An `Array` of `String`s describing the updates that were made
     */
    public func replyToTicket(ticket: Ticket, ticketFields: [String:Any]) async throws -> [String] {
        for hyperlink in ticket._hyperlinks {
            if hyperlink.ref == "correspond" {
                let jsonData = try JSONSerialization.data(withJSONObject: ticketFields)
                let endpoint = Endpoint(httpClient: self.httpClient!, url: hyperlink._url, authenticationType: self.authenticationType, credentials: self.credentials, method: .POST, bodyData: jsonData, bodyContentType: "application/json", etag: ticket.etag)
                let response = try await endpoint.makeRequest()
                let data = try await response.body.collect(upTo: 1024 * 1024 * 100) // 100MB
                if response.status.code == 412 {
                    // Invalid ETag
                    throw TicketError.PreconditionFailed
                }
                else if response.status.code == 201 {
                    do {
                        let json = try JSONSerialization.jsonObject(with: data)
                        let answerArr = try JSONDecoder().decode([String].self, from: JSONSerialization.data(withJSONObject: json))
                        return answerArr
                    }
                    catch {
                        throw TicketError.FailedToDecodeServerResponse
                    }
                }
                else {
                    throw TicketError.FailedToReplyToTicket
                }
            }
        }
        throw TicketError.PermissionError
    }
    
    /**
     Posts a comment to an existing ticket. Attachment content must be MIME base64 encoded
     - Parameters:
        - ticket: The `Ticket` to update
        - ticketFields: A dictionary of properties to post to the ticket
     - Returns: An `Array` of `String`s describing the updates that were made
     */
    public func commentTicket(ticket: Ticket, ticketFields: [String:Any]) async throws -> [String] {
        for hyperlink in ticket._hyperlinks {
            if hyperlink.ref == "comment" {
                let jsonData = try JSONSerialization.data(withJSONObject: ticketFields)
                let endpoint = Endpoint(httpClient: self.httpClient!, url: hyperlink._url, authenticationType: self.authenticationType, credentials: self.credentials, method: .POST, bodyData: jsonData, bodyContentType: "application/json", etag: ticket.etag)
                let response = try await endpoint.makeRequest()
                let data = try await response.body.collect(upTo: 1024 * 1024 * 100) // 100MB
                if response.status.code == 412 {
                    // Invalid ETag
                    throw TicketError.PreconditionFailed
                }
                else if response.status.code == 201 {
                    do {
                        let json = try JSONSerialization.jsonObject(with: data)
                        let answerArr = try JSONDecoder().decode([String].self, from: JSONSerialization.data(withJSONObject: json))
                        return answerArr
                    }
                    catch {
                        throw TicketError.FailedToDecodeServerResponse
                    }
                }
                else {
                    throw TicketError.FailedToCommentOnTicket
                }
            }
        }
        throw TicketError.PermissionError
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
        return try await getTicketInfo(id: Int(ticketRef.id)!)
    }
    
    /**
     Gets the information of a ticket
     - Parameters:
        - id: The numeric ID of the ticket
     - Returns:
        - A `Ticket` representing the ticket
     */
    public func getTicketInfo(id: Int) async throws -> Ticket {
        let endpoint = Endpoint(httpClient: self.httpClient!, host: self.rtServerHost, path: "/ticket/\(id)", authenticationType: self.authenticationType, credentials: self.credentials, method: .GET)
        let response = try await endpoint.makeRequest()
        let data = try await response.body.collect(upTo: 1024 * 1024 * 100) // 100MB
        if response.status.code == 200 {
            let json = try JSONSerialization.jsonObject(with: data)
            var ticket = try JSONDecoder().decode(Ticket.self, from: JSONSerialization.data(withJSONObject: json))
            for header in response.headers {
                if header.name == "ETag" {
                    ticket.etag = header.value.replacingOccurrences(of: "\"", with: "")
                }
            }
            ticket.localizeTicketDates()
            return ticket
        }
        else {
            throw TicketError.FailedToDecodeServerResponse
        }
    }
    
    public func getTicketHistory(id: Int) async throws -> [RTTransaction] {
        let endpoint = Endpoint(httpClient: self.httpClient!, host: self.rtServerHost, path: "/ticket/\(id)/history", authenticationType: self.authenticationType, credentials: self.credentials, method: .GET, fields: "Created,_hyperlinks,Creator,Data,Type,NewValue,Field")
        let response = try await endpoint.makeRequest()
        let data = try await response.body.collect(upTo: 1024 * 1024 * 100) // 100MB
        if response.status.code == 200 {
            let json = try JSONSerialization.jsonObject(with: data) as? [String : Any]
            let mergedPaginatedData = try await fetchAndMergePaginatedData(firstPage: json!, httpClient: self.httpClient!, host: self.rtServerHost, authenticationType: self.authenticationType, credentials: self.credentials)
            var returnArr : [RTTransaction] = []
            for entry in mergedPaginatedData {
                var castedEntry = try JSONDecoder().decode(RTTransaction.self, from: JSONSerialization.data(withJSONObject: entry))
                castedEntry.attachments = []
                castedEntry.localizeDates()
                returnArr.append(castedEntry)
            }
            return returnArr
        }
        else {
            throw TicketError.FailedToDecodeServerResponse
        }
    }
    
    public func getTicketHistory(ref: RTObject) async throws -> [RTTransaction] {
        if ref.type == "ticket" {
            return try await getTicketHistory(id: Int(ref.id)!)
        }
        throw TicketError.InvalidTicketRef
    }
    
    public func search(query: String, fields: String? = nil) async throws -> [RTObject] {
        if self.httpClient == nil {
            throw RequestTrackerFoundationError.RequestTrackerFoundationNotInitialized
        }
        let escapedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        if escapedQuery == nil {
            throw TicketError.SearchError
        }
        let endpoint = Endpoint(httpClient: self.httpClient!, host: self.rtServerHost, path: "/tickets", authenticationType: self.authenticationType, credentials: self.credentials, method: .GET, query: query, fields: fields)
        let response = try await endpoint.makeRequest()
        let data = try await response.body.collect(upTo: 1024 * 1024 * 100) // 100MB
        if response.status.code == 200 {
            let json = try JSONSerialization.jsonObject(with: data) as? [String:Any]
            if json == nil {
                throw TicketError.FailedToDecodeServerResponse
            }
            let rawRefs = try await fetchAndMergePaginatedData(firstPage: json!, httpClient: self.httpClient!, host: self.rtServerHost, authenticationType: self.authenticationType, credentials: self.credentials)
            var returnArr : [RTObject] = []
            for rawRef in rawRefs {
                returnArr.append(try RTObject(dictionary: rawRef))
            }
            return returnArr
        }
        else {
            print("[RTF] Error code: \(response.status.code)")
            throw TicketError.FailedToDecodeServerResponse
        }
    }
    
    // This endpoint is undocumented :(
    public func getTicketAttachments(ticket : Ticket) async throws -> [Attachment] {
        let endpoint = Endpoint(httpClient: self.httpClient!, host: self.rtServerHost, path: "/ticket/\(ticket.id)/attachments", authenticationType: self.authenticationType, credentials: self.credentials, method: .GET, fields: "Headers,Creator,Created,id,_hyperlinks,MessageId,Subject,TransactionId,Content,ContentType")
        let response = try await endpoint.makeRequest()
        let data = try await response.body.collect(upTo: 1024 * 1024 * 100) // 100MB
        if response.status.code == 200 {
            let json = try JSONSerialization.jsonObject(with: data) as? [String : Any]
            let mergedPaginatedData = try await fetchAndMergePaginatedData(firstPage: json!, httpClient: self.httpClient!, host: self.rtServerHost, authenticationType: self.authenticationType, credentials: self.credentials)
            var returnArr : [Attachment] = []
            for entry in mergedPaginatedData {
                let castedEntry = try JSONDecoder().decode(Attachment.self, from: JSONSerialization.data(withJSONObject: entry))
                returnArr.append(castedEntry)
            }
            return returnArr
        }
        else {
            throw TicketError.FailedToDecodeServerResponse
        }
    }
}
