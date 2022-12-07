//
//  File.swift
//  
//
//  Created by Chris on 12/6/22.
//

import Foundation

/**
 A struct that represents a generic RT Object
 */
public struct RTObject : Codable {
    var id : String
    var _url : URL
    var type : String
}

/**
 A struct that represents a RT queue
 */
public struct Queue : Codable {
    // TODO: Some of these types need to be changed to be more specific
    var SortOrder : String
    var CommentAddress : String
    var SLADisabled : String
    var TicketTransactionCustomFields : Array<String>
    var Disabled : String
    var Cc : Array<RTObject>
    var id : Int
    var LastUpdated : String
    var Name : String
    var Description : String
    var Creator : RTObject
    var AdminCc : Array<RTObject>
    var LastUpdatedBy : RTObject
    var _hyperlinks : Array<[String:String]>
    var CustomFields : Array<String>
    var Lifecycle : String
    var TicketCustomFields : Array<String>
    var CorrespondAddress : String
    var Created : String
    
}
