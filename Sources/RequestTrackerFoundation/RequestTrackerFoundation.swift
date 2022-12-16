import Foundation

/**
 Provides core errors that can be thrown by RequestTrackerFoundation
 */
public enum RequestTrackerFoundationError : Error {
    case ServerIsNotRT
    case InvalidCredentials
    case RequestTrackerFoundationNotInitialized
}

/**
 An extension for `RequestTrackerFoundationError` that provides error descriptions

 */
extension RequestTrackerFoundationError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .ServerIsNotRT: return "Unable to verify that the provided server is running RT. Make sure v2 of the REST API is running at '/REST/2.0'"
        case .InvalidCredentials: return "The provided credentials were not accepted by the server"
        case .RequestTrackerFoundationNotInitialized: return "You must initialize a RequestTrackerFoundation object before calling this function"
        }
    }
}

/**
 A class that represents this framework. This is the entry point and must be instantiated before other methods can be called.
 */
public struct RequestTrackerFoundation {

    var rtServerHost : String
    var authenticationType : AuthenticationType
    var credentials : String
    var urlSession : URLSession?
    
    /**
     Instantiates a new RequestTrackerFoundation
     
     - Parameters:
        - rtServerHost: The hostname of the RT server (for example: rt.example.com)
        - authenticationType: The `AuthenticationType` to use for authentication
        - credentials: The credentials to use for authentication. Should be applicable to `authenticationType`
     */
    public init(rtServerHost : String, authenticationType : AuthenticationType, credentials : String) async throws {
        print("Initializing RequestTrackerFoundation...")
        
        self.rtServerHost = rtServerHost
        self.authenticationType = authenticationType
        self.credentials = credentials
        
        print("Using RT Host \(self.rtServerHost) on port 443")
        self.urlSession = URLSession(configuration: .default)
    
        // Validate given URL is a RT server running REST 2 API
        // This validates credentials as well
        var endpoint = Endpoint(urlSession: self.urlSession!, host: self.rtServerHost, path: "/rt", authenticationType: .None, credentials: "", method: HTTPMethod.GET)
        var (data, response) = try await endpoint.makeRequest()
        switch response.statusCode {
        case 401: break
        default: throw RequestTrackerFoundationError.ServerIsNotRT
        }
        
        endpoint = Endpoint(urlSession: self.urlSession!, host: self.rtServerHost, path: "/rt", authenticationType: authenticationType, credentials: credentials, method: HTTPMethod.GET)
        (data, response) = try await endpoint.makeRequest()
        switch response.statusCode {
        case 200: break
        case 401: throw RequestTrackerFoundationError.InvalidCredentials
        default: throw RequestTrackerFoundationError.ServerIsNotRT
        }
        
        print("Status code looks OK, verifying actual response...")
        
        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String : Any]
            if json!["Version"] == nil {
                throw RequestTrackerFoundationError.ServerIsNotRT
            }
        }
        catch {
            throw RequestTrackerFoundationError.ServerIsNotRT
        }
        
        print("Host \(rtServerHost) verified as RT server running v2 of REST API")
        print("Request Tracker Foundation initialized")
    }
}
