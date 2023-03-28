//
//  File.swift
//  
//
//  Created by Chris on 12/5/22.
//

import Foundation
import FoundationNetworking
import AsyncHTTPClient
import Foundation
import Logging
import NIO
import NIOConcurrencyHelpers
import NIOFoundationCompat
import NIOHTTP1
import NIOHTTPCompression
import NIOSSL

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
 A class that represents an API endpoint
 */
class Endpoint {
    var httpClient : HTTPClient
    var url : URLComponents
    var authenticationType : AuthenticationType
    var credentials : String
    var method : HTTPMethod
    var bodyData : Data?
    var bodyContentType : String?
    var etag : String?
    var debug : Bool
    
    /**
     Instantiates a new `Endpoint`.
     
     - Parameters:
        - httpClient: The `HTTPClient` that should be used for making the request
        - host: The hostname of the RT server (for example: rt.example.com)
        - path: The URL path to send the request to. `"/REST/2.0"` is prepended to this
        - authenticationType: The `AuthenticationType` to use for authentication
        - credentials: The credentials to use for authentication. Should be applicable to `authenticationType`
        - method: The HTTP method to use in the request
        - bodyData: The data to send in the body of the request. Defaults to `nil`
        - bodyContentType: The `Content-Type` header to send with the request. Defaults to `nil`
        - etag: The value of the `If-Match` header to provide. Default to `nil`
     */
    init(httpClient : HTTPClient, host : String, path : String, authenticationType: AuthenticationType, credentials : String, method : HTTPMethod, bodyData: Data? = nil, bodyContentType: String? = nil, etag: String? = nil, query: String? = nil, fields: String? = nil, subfields: [String:String]? = nil, debug: Bool = false) {
        self.httpClient = httpClient
        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.path = "/REST/2.0" + path
        components.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "fields", value: fields)
        ]
        if subfields != nil {
            for (subfield, _fields) in subfields! {
                components.queryItems?.append(URLQueryItem(name: "fields[\(subfield)]", value: _fields))
            }
        }
        self.url = components
        self.authenticationType = authenticationType
        self.credentials = credentials
        self.method = method
        self.bodyData = bodyData
        self.bodyContentType = bodyContentType
        self.etag = etag
        self.debug = debug
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
    init(httpClient : HTTPClient, url : URL, authenticationType: AuthenticationType, credentials : String, method: HTTPMethod, bodyData: Data? = nil, bodyContentType: String? = nil, etag: String? = nil, debug: Bool = false) {
        self.httpClient = httpClient
        self.url = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        self.authenticationType = authenticationType
        self.credentials = credentials
        self.method = method
        self.bodyData = bodyData
        self.bodyContentType = bodyContentType
        self.etag = etag
        self.debug = debug
    }

    /**
     Perform the API request
     */
    func makeRequest() async throws -> HTTPClientResponse {
        
        var urlRequest = HTTPClientRequest(url: self.url.string!)
        if self.method == .POST || self.method == .PUT {
            urlRequest.body = .bytes(self.bodyData!)
            urlRequest.headers.add(name: "Content-Type", value: self.bodyContentType!)
        }
        if self.method == .PUT {
            if self.etag == nil {
                throw EndpointError.ETagNotSpecified
            }
            urlRequest.headers.add(name: "If-Match", value: self.etag!)
        }
        urlRequest.method = self.method
        urlRequest.headers.add(name: "User-Agent", value: "RequestTrackerFoundation/1.0")
        
        if self.authenticationType == .BasicAuth {
            if !self.credentials.contains(":") {
                throw EndpointError.InvalidCredentials
            }
            urlRequest.headers.add(name: "Authorization", value: "Basic \(self.credentials.data(using: .utf8)!.base64EncodedString())")
        }
        
        else if self.authenticationType == .TokenAuth {
            urlRequest.headers.add(name: "Authorization", value: "token \(self.credentials)")
        }
        do {
            if self.debug {
                print("DEBUG: Printing URLRequest before sending:")
                print(urlRequest)
            }
            let response = try await httpClient.execute(urlRequest, timeout: .seconds(30))
            return response
        }
        catch {
            throw EndpointError.NetworkRequestFailed
        }
    }
}
