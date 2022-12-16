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
    case InvalidCredentials, ETagNotSpecified, NetworkRequestFailed
}

/**
 An extension for `EndpointError` that provides error descriptions
 */
extension EndpointError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .InvalidCredentials: return "The provided basic credentials are not in the username:password format"
        case .ETagNotSpecified: return "An ETag value was not provided. While not technically required by RT, RequestTrackerFoundation enforces its use"
        case .NetworkRequestFailed: return "The network request failed"
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
 Provides available HTTP methods
 */
public enum HTTPMethod : String {
    case GET, POST, PUT
}

/**
 A class that represents an API endpoint
 */
class Endpoint {
    var urlSession : URLSession
    var url : URLComponents
    var authenticationType : AuthenticationType
    var credentials : String
    var method : HTTPMethod
    var bodyData : Data?
    var bodyContentType : String?
    var etag : String?
    
    /**
     Instantiates a new `Endpoint`.
     
     - Parameters:
        - urlSession: The `URLSession` that should be used for making the request
        - host: The hostname of the RT server (for example: rt.example.com)
        - path: The URL path to send the request to. `"/REST/2.0"` is prepended to this
        - authenticationType: The `AuthenticationType` to use for authentication
        - credentials: The credentials to use for authentication. Should be applicable to `authenticationType`
        - method: The HTTP method to use in the request
        - bodyData: The data to send in the body of the request. Defaults to `nil`
        - bodyContentType: The `Content-Type` header to send with the request. Defaults to `nil`
        - etag: The value of the `If-Match` header to provide. Default to `nil`
     */
    init(urlSession : URLSession, host : String, path : String, authenticationType: AuthenticationType, credentials : String, method : HTTPMethod, bodyData: Data? = nil, bodyContentType: String? = nil, etag: String? = nil) {
        self.urlSession = urlSession
        var components = URLComponents()
        // This should be https
        components.scheme = "http"
        components.host = host
        components.path = "/REST/2.0" + path
        self.url = components
        self.authenticationType = authenticationType
        self.credentials = credentials
        self.method = method
        self.bodyData = bodyData
        self.bodyContentType = bodyContentType
        self.etag = etag
    }
    
    /**
     Instantiates a new `Endpoint`.
     
     - Parameters:
        - urlSession: The `URLSession` that should be used for making the request
        - url: The full `URL`that represents the API endpoint
        - authenticationType: The `AuthenticationType` to use for authentication
        - credentials: The credentials to use for authentication. Should be applicable to `authenticationType`
        - method: The HTTP method to use in the request
        - bodyData: The data to send in the body of the request. Defaults to `nil`
        - bodyContentType: The `Content-Type` header to send with the request. Defaults to `nil`
        - etag: The value of the `If-Match` header to provide. Default to `nil`
     */
    init(urlSession : URLSession, url : URL, authenticationType: AuthenticationType, credentials : String, method: HTTPMethod, bodyData: Data? = nil, bodyContentType: String? = nil, etag: String? = nil) {
        self.urlSession = urlSession
        self.url = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        self.authenticationType = authenticationType
        self.credentials = credentials
        self.method = method
        self.bodyData = bodyData
        self.bodyContentType = bodyContentType
        self.etag = etag
    }

    /**
     Perform the API request
     */
    func makeRequest() async throws -> (Data, HTTPURLResponse) {
        var urlRequest = URLRequest(url: self.url.url!)
        if self.method == HTTPMethod.POST || self.method == HTTPMethod.PUT {
            urlRequest.httpBody = self.bodyData
            urlRequest.setValue(self.bodyContentType, forHTTPHeaderField: "Content-Type")
        }
        if self.method == HTTPMethod.PUT {
            if self.etag == nil {
                throw EndpointError.ETagNotSpecified
            }
            urlRequest.setValue(self.etag!, forHTTPHeaderField: "If-Match")
        }
        urlRequest.httpMethod = self.method.rawValue
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
        do {
            let (data, response) = try await self.urlSession.data(for: urlRequest)
            return (data, response as! HTTPURLResponse)
        }
        catch {
            throw EndpointError.NetworkRequestFailed
        }
    }
}
