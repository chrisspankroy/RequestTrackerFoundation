//
//  File.swift
//  
//
//  Created by Chris on 12/5/22.
//

import Foundation

/**
 Provides possible errors that can be thrown when making an endpoint request
 */
enum EndpointError : Error {
    case InvalidCredentials
}

/**
 An extension for `EndpointError` that provides error descriptions
 */
extension EndpointError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .InvalidCredentials: return "The provided basic credentials are not in the username:password format"
        }
    }
}

/**
 Provides supported authentication type
 */
public enum AuthenticationType : String {
    case BasicAuth, TokenAuth, None
}

/**
 A class that represents an API endpoint
 */
class Endpoint {
    var urlSession : URLSession
    var url : URLComponents
    var authenticationType : AuthenticationType
    var credentials : String
    var response : HTTPURLResponse?
    var responseData : Data?
    
    /**
     Instantiates a new `Endpoint`.
     
     - Parameters:
        - urlSession: The `URLSession` that should be used for making the request
        - host: The hostname of the RT server (for example: rt.example.com)
        - path: The URL path to send the request to. `"/REST/2.0"` is prepended to this
        - authenticationType: The `AuthenticationType` to use for authentication
        - credentials: The credentials to use for authentication. Should be applicable to `authenticationType`
     */
    init(urlSession : URLSession, host : String, path : String, authenticationType: AuthenticationType, credentials : String) {
        self.urlSession = urlSession
        var components = URLComponents()
        // This should be https
        components.scheme = "http"
        components.host = host
        components.path = "/REST/2.0" + path
        self.url = components
        self.authenticationType = authenticationType
        self.credentials = credentials
    }
    
    /**
     Instantiates a new `Endpoint`.
     
     - Parameters:
        - urlSession: The `URLSession` that should be used for making the request
        - url: The full `URL`that represents the API endpoint
        - authenticationType: The `AuthenticationType` to use for authentication
        - credentials: The credentials to use for authentication. Should be applicable to `authenticationType`
     */
    init(urlSession : URLSession, url : URL, authenticationType: AuthenticationType, credentials : String) {
        self.urlSession = urlSession
        self.url = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        self.authenticationType = authenticationType
        self.credentials = credentials
    }

    /**
     Perform the API request
     */
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
