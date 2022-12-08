//
//  Utilities.swift
//  
//
//  Created by Chris on 12/6/22.
//

import Foundation

/**
 Provides possible errors that can be thrown when running a utility function
 */
enum UtilityError : Error {
    case InvalidFirstPage, FailedToFetchPaginatedData, UnableToMergeDictionaries
}

/**
 An extension for `UtilityError` that provides error descriptions
 */
extension UtilityError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .InvalidFirstPage: return "Refusing to fetch/merge paginated data since a page other than the first page was provided"
        case .FailedToFetchPaginatedData: return "A request for a specific page of data failed"
        case .UnableToMergeDictionaries: return "Merging dictionaries failed"
        }
    }
}

/**
 Checks if the provided keys exist
 
 - Parameters:
    - dict: The dictionary to check
    - keysToCheck: An `Array` of keys to verify exist
 
 - Returns: `true` if all keys exist. `false` otherwise
 */
func keysExist(dict: [String : Any], keysToCheck: [String]) -> Bool {
    for key in keysToCheck {
        if dict[key] == nil {
            return false
        }
    }
    return true
}

/**
 Validates that a paginated response from RT is valid
 
 - Parameters:
    - page: The raw paginated JSON data from the server
 
 - Returns: `true` if the page is valid. `false` otherwise
 */
func validatePaginatedResponse(page : [String : Any]?) -> Bool {
    if page == nil {
        return false
    }
    return keysExist(dict: page!, keysToCheck: ["page", "total", "pages", "count", "per_page", "items"])
}

// Returns a NEW merged dict
// Currently allows duplicates
/**
 Creates a new dictionary that is the result of merging `lhs` and `rhs`. Duplicate values are allowed
 
 - Parameters:
    - lhs: One dictionary to merge
    - rhs: The other dictionary to merge
 
 - Returns: A new dictionary that is the result of merging `lhs` and `rhs`
 */
func mergeDicts(lhs: Any?, rhs: Any?) throws -> Array<[String:Any]> {
    let left = lhs as! Array<[String:Any]>
    let right = rhs as! Array<[String:Any]>
    return left + right
}

/**
 Takes the first page of paginated data, and fetches/merges the rest of the pages
 
 - Parameters:
    - firstPage: The raw JSON representing the first page
    - urlSession: The `URLSession` that the rest of the data should be fetched in
    - host: The host that should be queried. Should be equivalent to `rtServerHost`
    - authenticationType: The `AuthenticationType` to use for authentication
    - credentials: The credentials to use for authentication. Should be applicable to `authenticationType`
 
 - Returns: A de-paginated array of dictionaries
 */
func fetchAndMergePaginatedData(firstPage: [String : Any], urlSession: URLSession, host: String, authenticationType: AuthenticationType, credentials: String) async throws -> Array<[String : Any]> {
    if firstPage["next_page"] == nil && firstPage["prev_page"] == nil {
        // If these doesn't exist, then there is only one page
        return [firstPage]
    }
    else if firstPage["prev_page"] != nil {
        throw UtilityError.InvalidFirstPage
    }
    // Once here, next_page should always exist and prev_page should never exist
    var returnDict = firstPage["items"] as! Array<[String:Any]>
    var next_page_url = URL(string: firstPage["next_page"] as! String)
    while next_page_url != nil {
        let endpoint = Endpoint(urlSession: urlSession, url: next_page_url!, authenticationType: authenticationType, credentials: credentials, method: HTTPMethod.GET)
        try await endpoint.makeRequest()
        if endpoint.response?.statusCode == 200 {
            do {
                let json = try JSONSerialization.jsonObject(with: endpoint.responseData!) as? [String : Any]
                if validatePaginatedResponse(page: json) {
                    do {
                        returnDict = try mergeDicts(lhs: returnDict, rhs: json!["items"])
                    }
                    catch {
                        throw UtilityError.FailedToFetchPaginatedData
                    }
                    if json!["next_page"] == nil {
                        break
                    }
                    else {
                        next_page_url = URL(string: (json!["next_page"] as! String))
                        //print("Setting next URL to \(next_page_url)")
                    }
                }
            }
            catch {
                throw UtilityError.FailedToFetchPaginatedData
            }
        }
        else {
            throw UtilityError.FailedToFetchPaginatedData
        }
    }
    return returnDict
}
