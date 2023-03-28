//
//  File.swift
//  
//  Representations of various RT structures
//  Created by Chris on 12/6/22.
//

import Foundation
import FoundationNetworking
//import SwiftUI
//import WebKit

/**
 A struct that represents a generic RT Object
 */
public struct RTObject : Codable, Hashable, Identifiable {
    public var id : String
    public var _url : URL
    public var type : String
    
    // Only used in queue refs. nil otherwise
    public var Name : String?

    init(dictionary: [String:Any]) throws {
        self = try JSONDecoder().decode(RTObject.self, from: JSONSerialization.data(withJSONObject: dictionary))
    }
}

/**
 A struct that represents a RT API hyperlink
 */
public struct Hyperlink : Codable, Hashable, Identifiable {
    public var id : String?
    public var ref : String
    public var type : String?
    public var _url : URL
    public var from : String?
    public var label : String?
    public var to : String?
    public var update : String?
}

/**
 A struct that represents a RT queue
 */
public struct Queue : Codable, Identifiable, Hashable {
    public var SortOrder : String
    public var CommentAddress : String
    public var SLADisabled : String
    // TODO: need to test a scenario where this isnt empty so i can see what the structure looks like
    public var TicketTransactionCustomFields : Array<String>
    public var Disabled : String
    public var Cc : Array<RTObject>
    public var id : Int
    public var LastUpdated : String
    public var Name : String
    public var Description : String
    public var Creator : RTObject
    public var AdminCc : Array<RTObject>
    public var LastUpdatedBy : RTObject
    public var _hyperlinks : Array<Hyperlink>
    // TODO: need to test a scenario where this isnt empty so i can see what the structure looks like
    public var CustomFields : Array<String>
    public var Lifecycle : String
    // TODO: need to test a scenario where this isnt empty so i can see what the structure looks like
    public var TicketCustomFields : Array<String>
    public var CorrespondAddress : String
    public var Created : String
    
}

/**
 A struct that represents a custom field
 */
public struct CustomField : Codable, Identifiable, Hashable {
    public var id : String
    public var type : String
    public var _url : URL
    public var values : [String]
    public var name : String
}

/**
 A struct that represents a RT ticket
 */
public struct Ticket : Codable, Identifiable, Hashable {
    public var etag : String?
    public var AdminCc : Array<RTObject>
    public var Cc : Array<RTObject>
    public var Created : String
    public var Creator : RTObject
    public var CustomFields : [CustomField]
    public var Due : String
    // This is equivalent to the ticketRef
    public var EffectiveID : RTObject?
    public var FinalPriority : String
    public var InitialPriority : String
    public var LastUpdated : String
    public var LastUpdatedBy : RTObject
    public var Owner : RTObject
    public var Priority : String
    public var Queue : RTObject
    public var Requestor : Array<RTObject>
    public var Resolved : String
    public var Started : String
    public var Starts : String
    public var Status : String
    public var Subject : String
    public var TimeEstimated : String
    public var TimeLeft : String
    public var TimeWorked : String
    public var _hyperlinks : Array<Hyperlink>
    public var id : Int

    public func getCFValue(fieldName: String) -> [String]? {
        for field in CustomFields {
            if field.name == fieldName {
                return field.values
            }
        }
        return nil
    }
    
    public func getRequestorsString() -> String {
        if Requestor.count == 0 {
            return "There are no requestors"
        }
        var retString = ""
        for (index, requestor) in Requestor.enumerated() {
            retString += requestor.id
            if index != Requestor.count - 1 {
                retString += ", "
            }
        }
        return retString
    }
    
    public func getCcString() -> String {
        if Cc.count == 0 {
            return "There are no Ccs"
        }
        var retString = ""
        for (index, cc) in Cc.enumerated() {
            retString += cc.id
            if index != Cc.count - 1 {
                retString += ", "
            }
        }
        return retString
    }
    
    public func getAdminCcString() -> String {
        if AdminCc.count == 0 {
            return "There are no AdminCcs"
        }
        var retString = ""
        for (index, admincc) in AdminCc.enumerated() {
            retString += admincc.id
            if index != AdminCc.count - 1 {
                retString += ", "
            }
        }
        return retString
    }
    
    
    public mutating func localizeTicketDates() {
        var localTimeZoneAbbreviation: String { return TimeZone.current.abbreviation() ?? "" }
        let localTimeZoneSeconds = TimeZone(secondsFromGMT: TimeZone.current.secondsFromGMT())
        let originalFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        let newFormat = "E MMM dd HH:mm:ss yyyy '\(localTimeZoneAbbreviation)'"
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = localTimeZoneSeconds
        
        if Created != "1970-01-01T00:00:00Z" {
            dateFormatter.dateFormat = originalFormat
            let date = dateFormatter.date(from: Created)
            dateFormatter.dateFormat = newFormat
            let resultString = dateFormatter.string(from: date!)
            Created = resultString
        }
        else {
            Created = "Not set"
        }
        
        if Due != "1970-01-01T00:00:00Z" {
            dateFormatter.dateFormat = originalFormat
            let date = dateFormatter.date(from: Due)
            dateFormatter.dateFormat = newFormat
            let resultString = dateFormatter.string(from: date!)
            Due = resultString
        }
        else {
            Due = "Not set"
        }
        
        if LastUpdated != "1970-01-01T00:00:00Z" {
            dateFormatter.dateFormat = originalFormat
            let date = dateFormatter.date(from: LastUpdated)
            dateFormatter.dateFormat = newFormat
            let resultString = dateFormatter.string(from: date!)
            LastUpdated = resultString
        }
        else {
            LastUpdated = "Not set"
        }
        
        if Resolved != "1970-01-01T00:00:00Z" {
            dateFormatter.dateFormat = originalFormat
            let date = dateFormatter.date(from: Resolved)
            dateFormatter.dateFormat = newFormat
            let resultString = dateFormatter.string(from: date!)
            Resolved = resultString
        }
        else {
            Resolved = "Not set"
        }

        if Started != "1970-01-01T00:00:00Z" {
            dateFormatter.dateFormat = originalFormat
            let date = dateFormatter.date(from: Started)
            dateFormatter.dateFormat = newFormat
            let resultString = dateFormatter.string(from: date!)
            Started = resultString
        }
        else {
            Started = "Not set"
        }
        
        if Starts != "1970-01-01T00:00:00Z" {
            dateFormatter.dateFormat = originalFormat
            let date = dateFormatter.date(from: Starts)
            dateFormatter.dateFormat = newFormat
            let resultString = dateFormatter.string(from: date!)
            Starts = resultString
        }
        else {
            Starts = "Not set"
        }
    }
}

public struct RTTransaction : Codable {
    public var id : String
    public var Creator : RTObject
    // This is injected after fetching
    public var CreatorInjected : String?
    public var Created : String
    public var Data : String?
    public var _hyperlinks : [Hyperlink]
    public var ItemType : String
    public var _url : URL
    public var type : String
    public var NewValue : String
    public var Field : String
    // This is injected after fetching, includes the actual user name and info
    public var NewValueInjected : String?
    public var attachments : [Attachment]? = []
    
    // Workaround to get Type to work
    private enum CodingKeys : String, CodingKey {
        case id, Creator, CreatorInjected, Created, Data, _hyperlinks, ItemType = "Type", _url, type, NewValue, Field, NewValueInjected, attachments
    }
    
    public mutating func localizeDates() {
        var localTimeZoneAbbreviation: String { return TimeZone.current.abbreviation() ?? "" }
        let localTimeZoneSeconds = TimeZone(secondsFromGMT: TimeZone.current.secondsFromGMT())
        let originalFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        let newFormat = "E MMM dd HH:mm:ss yyyy '\(localTimeZoneAbbreviation)'"
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = localTimeZoneSeconds
        
        if Created != "1970-01-01T00:00:00Z" {
            dateFormatter.dateFormat = originalFormat
            let date = dateFormatter.date(from: Created)
            dateFormatter.dateFormat = newFormat
            let resultString = dateFormatter.string(from: date!)
            Created = resultString
        }
        else {
            Created = "Not set"
        }
    }
}

public struct Attachment : Codable {
    public var id : Int
    public var Content : String
    public var Creator : RTObject
    public var type : String
    public var Created : String
    public var ContentType : String
    public var _hyperlinks : [Hyperlink]
    public var MessageId : String
    public var Headers : String
    public var Subject : String
    public var _url : URL
    public var TransactionId : String
}

public struct User : Codable {
    public var Name : String
    public var id : Int
    public var RealName : String
    public var _url : URL
    public var type : String
}
