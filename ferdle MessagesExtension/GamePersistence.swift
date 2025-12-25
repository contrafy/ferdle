//
//  GamePersistence.swift
//  ferdle MessagesExtension
//
//  Read/write/delete persisted game state using UserDefaults.
//

import Foundation

struct GamePersistence {

    private static let persistenceKey = "ferdle.persistedGameState.v1"

    /// Loads the persisted game state from UserDefaults.
    /// - Returns: The persisted state, or nil if none exists or decoding fails.
    static func load() -> PersistedGameState? {
        guard let data = UserDefaults.standard.data(forKey: persistenceKey) else {
            return nil
        }

        let decoder = JSONDecoder()
        return try? decoder.decode(PersistedGameState.self, from: data)
    }

    /// Saves the game state to UserDefaults.
    /// - Parameter state: The game state to persist.
    static func save(_ state: PersistedGameState) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(state) {
            UserDefaults.standard.set(data, forKey: persistenceKey)
        }
    }

    /// Clears the persisted game state from UserDefaults.
    static func clear() {
        UserDefaults.standard.removeObject(forKey: persistenceKey)
    }
}
