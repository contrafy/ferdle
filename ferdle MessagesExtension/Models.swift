//
//  Models.swift
//  ferdle MessagesExtension
//
//  Codable models and enums for board tiles, results, keyboard status, and persisted state.
//

import Foundation

// MARK: - NYT Wordle API Response

struct NYTWordleResponse: Codable {
    let id: Int
    let solution: String
    let printDate: String
    let daysSinceLaunch: Int
    let editor: String

    enum CodingKeys: String, CodingKey {
        case id
        case solution
        case printDate = "print_date"
        case daysSinceLaunch = "days_since_launch"
        case editor
    }
}

// MARK: - Tile Models

struct Tile: Codable, Equatable {
    var letter: String
    var result: TileResult?
    var isRevealed: Bool

    init(letter: String = "", result: TileResult? = nil, isRevealed: Bool = false) {
        self.letter = letter
        self.result = result
        self.isRevealed = isRevealed
    }
}

enum TileResult: String, Codable, Equatable {
    case miss
    case present
    case correct
}

// MARK: - Keyboard Status

enum KeyStatus: String, Codable, Equatable {
    case unknown
    case miss
    case present
    case correct

    // Precedence for keyboard updates: correct > present > miss
    func shouldUpdate(to newStatus: KeyStatus) -> Bool {
        switch self {
        case .unknown:
            return true
        case .miss:
            return newStatus == .present || newStatus == .correct
        case .present:
            return newStatus == .correct
        case .correct:
            return false
        }
    }
}

// MARK: - Game Phase

enum GamePhase: String, Codable, Equatable {
    case loading
    case playing
    case revealing
    case won
    case lost
}

// MARK: - Persisted State

struct PersistedGameState: Codable {
    let printDate: String
    let daysSinceLaunch: Int
    let board: [[Tile]]
    let currentRowIndex: Int
    let currentColIndex: Int
    let keyboardStatuses: [String: KeyStatus]
    let phase: String
    let submittedRowsCount: Int
}
