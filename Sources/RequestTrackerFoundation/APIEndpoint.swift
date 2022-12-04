//
//  APIEndpoint.swift
//  
//
//  Created by Chris on 12/4/22.
//

import Foundation

enum APIEndpointType {
    case GET, POST
}

public class APIEndpoint {
    var endpointString : String
    var requestType : APIEndpointType
    
    init(endpointString: String, requestType: APIEndpointType) {
        self.endpointString = endpointString
        self.requestType = requestType
    }
    
    func makeRequest() {
        
    }
}
