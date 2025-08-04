//
//  Enums.swift
//  NetworkManager
//
//  Created by aman.gupta on 30/07/25.
//

import Foundation

/*
 GET:
 Used to retrieve data from the server. It should not alter the state of the server. Example: fetching a list of products or a specific user's details.
 
 POST:
 Used to create a new resource on the server. Data is sent in the request body. Example: adding a new product to an e-commerce store or submitting a form.
 
 PUT:
 Used to update an existing resource or create a new resource if it doesn't exist, by replacing the entire resource with the provided data. It is idempotent, meaning multiple identical PUT requests have the same effect. Example: updating all fields of a user's profile.
 
 PATCH:
 Used to partially update an existing resource. Only the specified fields in the request body are modified, leaving other fields untouched. Example: updating only a user's email address.
 
 DELETE:
 Used to remove a resource from the server. Example: deleting a specific product or user account.
 */

public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}


/*
 APIError For handling all the error thrown by API response
 */

public enum APIError: Error {
    
    case invalidURL
    case requestFailed(Error)
    case noData
    case decodingFailed(Error)
    case unauthorized
    case forbidden
    case notFound
    case serverError(statusCode: Int)
    case unknownStatusCode(statusCode: Int)
    case timeout
    case noInternet
    case cancelled
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The URL provided was invalid."
        case .requestFailed(let error):
            return "The request failed with error: \(error.localizedDescription)"
        case .noData:
            return "No data was received from the server."
        case .decodingFailed(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .unauthorized:
            return "Unauthorized access. Please log in again."
        case .forbidden:
            return "You do not have permission to access this resource."
        case .notFound:
            return "The requested resource was not found."
        case .serverError(let statusCode):
            return "Server error with status code \(statusCode)."
        case .unknownStatusCode(let statusCode):
            return "Received unknown HTTP status code: \(statusCode)."
        case .timeout:
            return "The request timed out."
        case .noInternet:
            return "No internet connection."
        case .cancelled:
            return "The request was cancelled."
        }
    }
}

/*
 🧩 FlexibleResponse Enum
 */

public enum FlexibleResponse<T: Codable> {
    case typed(T)
    case raw([String: Any])
}
