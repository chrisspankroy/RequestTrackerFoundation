//
//  Utilities.swift
//  
//
//  Created by Chris on 12/6/22.
//

import Foundation

enum UtilityError : Error {
    case InvalidFirstPage, FailedToFetchPaginatedData, UnableToMergeDictionaries
}

extension UtilityError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .InvalidFirstPage: return "Refusing to fetch/merge paginated data since a page other than the first page was provided"
        case .FailedToFetchPaginatedData: return "A request for a specific page of data failed"
        case .UnableToMergeDictionaries: return "Merging dictionaries failed"
        }
    }
}

func keysExist(dict: [String : Any], keysToCheck: [String]) -> Bool {
    for key in keysToCheck {
        if dict[key] == nil {
            return false
        }
    }
    return true
}

func validatePaginatedResponse(page : [String : Any]?) -> Bool {
    if page == nil {
        return false
    }
    return keysExist(dict: page!, keysToCheck: ["page", "total", "pages", "count", "per_page", "items"])
}

// Returns a NEW merged dict
// Currently allows duplicates
func mergeDicts(lhs: Any?, rhs: Any?) throws -> Array<[String:Any]> {
    let left = lhs as! Array<[String:Any]>
    let right = rhs as! Array<[String:Any]>
    return left + right
}

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
        var endpoint = Endpoint(urlSession: urlSession, url: next_page_url!, authenticationType: authenticationType, credentials: credentials)
        try await endpoint.makeRequest()
        if endpoint.response?.statusCode == 200 {
            do {
                var json = try JSONSerialization.jsonObject(with: endpoint.responseData!) as? [String : Any]
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
