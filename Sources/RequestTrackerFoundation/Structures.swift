//
//  File.swift
//  
//  Representations of various RT structures
//  Created by Chris on 12/6/22.
//

import Foundation

/**
 A struct that represents a generic RT Object
 */
public struct RTObject : Codable, Hashable {
    public var id : String
    public var _url : URL
    public var type : String
}

/**
 A struct that represents a RT API hyperlink
 */
public struct Hyperlink : Codable, Hashable {
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
 A struct that represents a RT ticket
 */
public struct Ticket : Codable, Identifiable, Hashable {
    public var etag : String?
    public var AdminCc : Array<RTObject>
    public var Cc : Array<RTObject>
    public var Created : String
    public var Creator : RTObject
    public var CustomFields : Array<String>
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
}
