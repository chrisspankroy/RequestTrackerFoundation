import Foundation

public enum RequestTrackerFoundationError : Error {
    case ServerIsNotRT, UnknownErrorCode, InvalidCredentials
}

public struct RequestTrackerFoundation {

    var rtServerHost : String
    var authenticationType : AuthenticationType
    var credentials : String
    var urlSession : URLSession?
    
    public init(rtServerHost : String, authenticationType : AuthenticationType, credentials : String) async throws {
        print("Initializing RequestTrackerFoundation...")
        
        self.rtServerHost = rtServerHost
        self.authenticationType = authenticationType
        self.credentials = credentials
        
        print("Using RT Host \(self.rtServerHost) on port 443")
        self.urlSession = URLSession(configuration: .default)
    
        // Validate given URL is a RT server running REST 2 API
        // There isn't an endpoint for this, so I make 2 requests to somewhat handle it
        // One to /REST/2.0/queues/all with no creds that should return 401
        // And one to /REST/2.0/queues/all with creds that should return 200
        // This has the benefit of validating credentials too
        var endpoint = Endpoint(urlSession: self.urlSession!, host: self.rtServerHost, path: "/queues/all", authenticationType: .None, credentials: "")
        try await endpoint.makeRequest()
        if endpoint.response != nil && endpoint.responseData != nil {
            if endpoint.response!.statusCode != 401 {
                throw RequestTrackerFoundationError.ServerIsNotRT
            }
        }
        
        endpoint = Endpoint(urlSession: self.urlSession!, host: self.rtServerHost, path: "/queues/all", authenticationType: self.authenticationType, credentials: credentials)
        try await endpoint.makeRequest()
        if endpoint.response != nil {
            switch endpoint.response!.statusCode {
            case 200: break
            case 401: throw RequestTrackerFoundationError.InvalidCredentials
            default: throw RequestTrackerFoundationError.ServerIsNotRT
            }
        }
        
        print("Host \(rtServerHost) verified as RT server running v2 of REST API")
        print("Request Tracker Foundation initialized")
    }
    
    
}
