//
//  WordleAPI.swift
//  ferdle MessagesExtension
//
//  Fetch today's NYT Wordle JSON using async/await.
//

import Foundation

enum WordleAPIError: Error {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
}

struct WordleAPI {

    /// Fetches the Wordle puzzle for the specified date.
    /// - Parameter date: The date for which to fetch the puzzle (defaults to today).
    /// - Returns: The NYT Wordle response containing the solution and metadata.
    static func fetchPuzzle(for date: Date = Date()) async throws -> NYTWordleResponse {
        let dateString = todayDateString(for: date)

        guard let url = URL(string: "https://www.nytimes.com/svc/wordle/v2/\(dateString).json") else {
            throw WordleAPIError.invalidURL
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoder = JSONDecoder()
            let response = try decoder.decode(NYTWordleResponse.self, from: data)
            return response
        } catch let error as DecodingError {
            throw WordleAPIError.decodingError(error)
        } catch {
            throw WordleAPIError.networkError(error)
        }
    }

    /// Formats a date as YYYY-MM-DD string.
    /// - Parameter date: The date to format.
    /// - Returns: The formatted date string.
    static func todayDateString(for date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "America/New_York") // NYT uses Eastern Time
        return formatter.string(from: date)
    }
}
