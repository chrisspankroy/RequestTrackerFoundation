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
    var httpClient : HTTPClient?
    
    /**
     Instantiates a new RequestTrackerFoundation
     
     - Parameters:
        - rtServerHost: The hostname of the RT server (for example: rt.example.com)
        - authenticationType: The `AuthenticationType` to use for authentication
        - credentials: The credentials to use for authentication. Should be applicable to `authenticationType`
     */
    public init?(rtServerHost : String, authenticationType : AuthenticationType, credentials : String) async throws {
        print("[RTF] Initializing RequestTrackerFoundation...")

        self.rtServerHost = rtServerHost
        self.authenticationType = authenticationType
        self.credentials = credentials
        
        print("[RTF] Using RT Host \(self.rtServerHost) on port 443")
        self.httpClient = HTTPClient(eventLoopGroupProvider: .createNew)
    
        // Validate given URL is a RT server running REST 2 API
        // This validates credentials as well
        var endpoint = Endpoint(httpClient: self.httpClient!, host: self.rtServerHost, path: "/rt", authenticationType: .None, credentials: "", method: .GET)
        var response = try await endpoint.makeRequest()

	if response.status.code != 401 {
                print("Specified server is not a RT server")
		await try shutdown()
		return nil
	}
        
        endpoint = Endpoint(httpClient: self.httpClient!, host: self.rtServerHost, path: "/rt", authenticationType: authenticationType, credentials: credentials, method: .GET)
        response = try await endpoint.makeRequest()
        let data = try await response.body.collect(upTo: 1024 * 1024 * 100) // 100MB

	if response.status.code == 401 {
		print("Provided credentials were invalid")
		await try shutdown()
		return nil
	}

        if response.status.code != 200 {
                print("Specified server is not a RT server")
                await try shutdown()
                return nil
        }
        
        print("[RTF] Status code looks OK, verifying actual response...")
        
        do {
            let json = try JSONSerialization.jsonObject(with: Data(buffer: data)) as? [String : Any]
            if json!["Version"] == nil {
		print("Specified server is not a RT server")
		await try shutdown()
		return nil
            }
        }
        catch {
	    print("Specified server is not a RT server")
	    await try shutdown()
	    return nil
        }
        print("[RTF] Host \(rtServerHost) verified as RT server running v2 of REST API")
        print("[RTF] Request Tracker Foundation initialized")
    }

    /**
    Shuts down HTTP Client (disruptive to any pending requests). This must be called.
     */
    public func shutdown() async throws {
        print("[RTF] Shutting down HTTP client...")
        try await self.httpClient!.shutdown()
        print("[RTF] HTTP client shutdown successful")
    }
}
