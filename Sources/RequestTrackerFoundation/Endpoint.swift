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

extension EndpointError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .InvalidCredentials: return "The provided basic credentials are not in the username:password format"
        }
    }
}

public enum AuthenticationType : String {
    case BasicAuth, TokenAuth, None
}

class Endpoint {
    var urlSession : URLSession
    var url : URLComponents
    var authenticationType : AuthenticationType
    var credentials : String
    var response : HTTPURLResponse?
    var responseData : Data?
    
    // This will be non-null if a custom response code should be used to indicate "success" (and prevent an error from being thrown)
    var successCode : Int?
    
    init(urlSession : URLSession, host : String, path : String, authenticationType: AuthenticationType, credentials : String, successCode : Int? = nil) {
        self.urlSession = urlSession
        var components = URLComponents()
        // This should be https
        components.scheme = "http"
        components.host = host
        components.path = "/REST/2.0" + path
        self.url = components
        self.authenticationType = authenticationType
        self.credentials = credentials
        self.successCode = successCode
    }
    
    init(urlSession : URLSession, url : URL, authenticationType: AuthenticationType, credentials : String, successCode : Int? = nil) {
        self.urlSession = urlSession
        self.url = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        self.authenticationType = authenticationType
        self.credentials = credentials
        self.successCode = successCode
    }

    func makeRequest() async throws {
        // this should be https
        var urlRequest = URLRequest(url: self.url.url!)
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
