import Foundation

public enum RequestTrackerFoundationError : Error {
    case ServerIsNotRT
    case InvalidCredentials
    case RequestTrackerFoundationNotInitialized
    case InvalidResponseFromServer
    case FailedToDecodeJSON
}

extension RequestTrackerFoundationError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .ServerIsNotRT: return "Unable to verify that the provided server is running RT. Make sure v2 of the REST API is running at '/REST/2.0'"
        case .InvalidCredentials: return "The provided credentials were not accepted by the server"
        case .RequestTrackerFoundationNotInitialized: return "You must initialize a RequestTrackerFoundation object before calling this function"
        case .InvalidResponseFromServer: return "The response returned from the server did not contain the JSON keys usually included in this type of response"
        case .FailedToDecodeJSON: return "Decoding the JSON data from the server failed"
        }
    }
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
        // This validates credentials as well
        var endpoint = Endpoint(urlSession: self.urlSession!, host: self.rtServerHost, path: "/rt", authenticationType: .None, credentials: "")
        try await endpoint.makeRequest()
        if endpoint.response != nil {
            switch endpoint.response!.statusCode {
            case 401: break
            default: throw RequestTrackerFoundationError.ServerIsNotRT
            }
        }
        
        endpoint = Endpoint(urlSession: self.urlSession!, host: self.rtServerHost, path: "/rt", authenticationType: authenticationType, credentials: credentials)
        try await endpoint.makeRequest()
        if endpoint.response != nil && endpoint.responseData != nil {
            switch endpoint.response!.statusCode {
            case 200: break
            case 401: throw RequestTrackerFoundationError.InvalidCredentials
            default: throw RequestTrackerFoundationError.ServerIsNotRT
            }
            print("Status code looks OK, verifying actual response...")
            do {
                let json = try JSONSerialization.jsonObject(with: endpoint.responseData!) as? [String : Any]
                if json!["Version"] == nil {
                    throw RequestTrackerFoundationError.ServerIsNotRT
                }
            }
            catch {
                throw RequestTrackerFoundationError.ServerIsNotRT
            }
        }
        
        print("Host \(rtServerHost) verified as RT server running v2 of REST API")
        print("Request Tracker Foundation initialized")
    }
}
