//
//  File.swift
//  
//
//  Created by Chris on 12/5/22.
//

import Foundation

enum EndpointError : Error {
    case InvalidCredentials
}

public enum AuthenticationType : String {
    case BasicAuth, TokenAuth, None
}

class Endpoint {
    var urlSession : URLSession
    var host : String
    var path : String
    var authenticationType : AuthenticationType
    var credentials : String
    var response : HTTPURLResponse?
    var responseData : Data?
    
    // This will be non-null if a custom response code should be used to indicate "success" (and prevent an error from being thrown)
    var successCode : Int?
    
    init(urlSession : URLSession, host : String, path : String, authenticationType: AuthenticationType, credentials : String, successCode : Int? = nil) {
        self.urlSession = urlSession
        self.host = host
        self.path = "/REST/2.0" + path
        self.authenticationType = authenticationType
        self.credentials = credentials
        self.successCode = successCode
    }

    func makeRequest() async throws {
        var endpointURL = URLComponents()
        endpointURL.host = self.host
        // this should be https
        endpointURL.scheme = "http"
        endpointURL.path = self.path
        var urlRequest = URLRequest(url: endpointURL.url!)
        urlRequest.httpMethod = "GET"
        urlRequest.setValue("RequestTrackerFoundation/1.0", forHTTPHeaderField: "User-Agent")
        
        if self.authenticationType == .BasicAuth {
            if !self.credentials.contains(":") {
                throw EndpointError.InvalidCredentials
            }
            urlRequest.setValue("Basic \(self.credentials.data(using: .utf8)!.base64EncodedString())", forHTTPHeaderField: "Authorization")
        }
        
        else if self.authenticationType == .TokenAuth {
            urlRequest.setValue("token \(self.credentials)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await self.urlSession.data(for: urlRequest)
        self.response = response as? HTTPURLResponse
        self.responseData = data
    }
}
