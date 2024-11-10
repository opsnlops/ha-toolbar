
import Foundation

/**
 Server-side error
 */
enum ServerError: Error, LocalizedError {
    case invalidURL
    case invalidConfiguration
    case networkError(String)
    case authenticationFailed
    case decodingFailed(String)
    case unknownError(String)

    var errorDescription: String? {
        switch self {
            case .invalidURL:
                return "The provided URL is invalid"
            case .invalidConfiguration:
                return "The configuration is invalid"
            case .networkError(let message):
                return "Network error occurred: \(message)"
            case .authenticationFailed:
                return "Authentication failed"
            case .decodingFailed(let message):
                return "Failed to decode the server response: \(message)"
            case .unknownError(let message):
                return "An unknown error occurred: \(message)"
        }
    }
}

