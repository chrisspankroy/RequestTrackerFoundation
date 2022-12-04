import Foundation

public struct RequestTrackerFoundation {
    public private(set) var text = "Hello, World!"

    var rtServerUrl : URL
    public init(rtServerUrl : URL) {
        self.rtServerUrl = rtServerUrl
        print("Initializing rtapic...")
        // Validate given URL is a RT server
        // Validate RT server is running REST2, not REST1
    }
}
