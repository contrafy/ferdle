//
//  GameViewModel.swift
//  ferdle MessagesExtension
//
//  Single source of truth for game state, input handling, evaluation, animations, and persistence.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class GameViewModel: ObservableObject {

    // MARK: - Published State

    @Published var solution: String = ""
    @Published var daysSinceLaunch: Int = 0
    @Published var printDate: String = ""

    @Published var board: [[Tile]] = Array(repeating: Array(repeating: Tile(), count: 5), count: 6)
    @Published var currentRowIndex: Int = 0
    @Published var currentColIndex: Int = 0

    @Published var gamePhase: GamePhase = .loading
    @Published var keyboardStatuses: [Character: KeyStatus] = [:]
    @Published var submittedRowsCount: Int = 0

    // MARK: - Configuration

    /// Configures the game for today's puzzle.
    /// Loads persisted state if it matches today's puzzle; otherwise starts fresh.
    func configureForToday(puzzle: NYTWordleResponse) {
        self.solution = puzzle.solution.uppercased()
        self.daysSinceLaunch = puzzle.daysSinceLaunch
        self.printDate = puzzle.printDate

        // Attempt to load persisted state
        if let persisted = GamePersistence.load(),
           persisted.printDate == puzzle.printDate,
           persisted.daysSinceLaunch == puzzle.daysSinceLaunch {
            // Restore state
            self.board = persisted.board
            self.currentRowIndex = persisted.currentRowIndex
            self.currentColIndex = persisted.currentColIndex
            self.submittedRowsCount = persisted.submittedRowsCount

            // Restore keyboard statuses
            var statuses: [Character: KeyStatus] = [:]
            for (key, value) in persisted.keyboardStatuses {
                if let char = key.first {
                    statuses[char] = value
                }
            }
            self.keyboardStatuses = statuses

            // Restore phase
            self.gamePhase = GamePhase(rawValue: persisted.phase) ?? .playing
        } else {
            // Start fresh
            resetBoard()
            self.gamePhase = .playing
        }
    }

    // MARK: - Input Handling

    /// Routes key presses to appropriate handlers.
    func handleKeyPress(_ key: String) {
        // Ignore input during reveal animation or when game is over
        guard gamePhase == .playing else { return }

        switch key {
        case "ENTER":
            submitGuess()
        case "DELETE":
            deleteLetter()
        default:
            // Only accept A-Z letters
            if key.count == 1, let char = key.first, char.isLetter {
                appendLetter(char)
            }
        }
    }

    /// Appends a letter to the current row if there's room.
    func appendLetter(_ letter: Character) {
        guard currentColIndex < 5 else { return }
        board[currentRowIndex][currentColIndex].letter = String(letter).uppercased()
        currentColIndex += 1
        persistIfNeeded()
    }

    /// Removes the last letter from the current row.
    func deleteLetter() {
        guard currentColIndex > 0 else { return }
        currentColIndex -= 1
        board[currentRowIndex][currentColIndex].letter = ""
        persistIfNeeded()
    }

    /// Submits the current guess if it has 5 letters.
    func submitGuess() {
        guard currentColIndex == 5 else { return }

        let guess = board[currentRowIndex].map { $0.letter }.joined()
        let results = evaluateGuess(guess: guess, solution: solution)

        // Apply results to the board
        for (index, result) in results.enumerated() {
            board[currentRowIndex][index].result = result
        }

        // Start reveal animation
        gamePhase = .revealing
        Task {
            await runRevealAnimation(row: currentRowIndex, results: results)
        }
    }

    // MARK: - Evaluation

    /// Evaluates a guess against the solution using Wordle's scoring algorithm.
    /// Handles duplicate letters correctly: greens first, then yellows from remaining letters.
    func evaluateGuess(guess: String, solution: String) -> [TileResult] {
        let guessChars = Array(guess.uppercased())
        let solutionChars = Array(solution.uppercased())
        var results = Array(repeating: TileResult.miss, count: 5)
        var remainingCounts: [Character: Int] = [:]

        // Count all solution letters
        for char in solutionChars {
            remainingCounts[char, default: 0] += 1
        }

        // Pass 1: Mark exact matches (greens) and decrement remaining counts
        for i in 0..<5 {
            if guessChars[i] == solutionChars[i] {
                results[i] = .correct
                remainingCounts[guessChars[i]]! -= 1
            }
        }

        // Pass 2: Mark present letters (yellows) from remaining counts
        for i in 0..<5 {
            if results[i] != .correct {
                if let count = remainingCounts[guessChars[i]], count > 0 {
                    results[i] = .present
                    remainingCounts[guessChars[i]]! -= 1
                }
            }
        }

        return results
    }

    /// Updates keyboard statuses based on guess results.
    /// Correct overrides present overrides miss.
    func applyResultsToKeyboard(guess: String, results: [TileResult]) {
        let guessChars = Array(guess.uppercased())

        for (index, char) in guessChars.enumerated() {
            let result = results[index]
            let newStatus: KeyStatus

            switch result {
            case .correct:
                newStatus = .correct
            case .present:
                newStatus = .present
            case .miss:
                newStatus = .miss
            }

            let currentStatus = keyboardStatuses[char] ?? .unknown
            if currentStatus.shouldUpdate(to: newStatus) {
                keyboardStatuses[char] = newStatus
            }
        }
    }

    // MARK: - Animation

    /// Reveals tiles sequentially with animation.
    func runRevealAnimation(row: Int, results: [TileResult]) async {
        for col in 0..<5 {
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.25)) {
                    board[row][col].isRevealed = true
                }
            }
            try? await Task.sleep(nanoseconds: 150_000_000) // 0.15 seconds
        }

        // After reveal, update keyboard and check end conditions
        let guess = board[row].map { $0.letter }.joined()
        applyResultsToKeyboard(guess: guess, results: results)

        submittedRowsCount += 1
        checkEndConditions(rowResults: results)

        if gamePhase != .won && gamePhase != .lost {
            currentRowIndex += 1
            currentColIndex = 0
            gamePhase = .playing
            persistIfNeeded()
        } else {
            // Game ended, clear persisted state
            clearPersistedState()
        }
    }

    /// Checks if the game has ended (win or loss).
    func checkEndConditions(rowResults: [TileResult]) {
        let isWin = rowResults.allSatisfy { $0 == .correct }

        if isWin {
            gamePhase = .won
        } else if currentRowIndex == 5 {
            // Just used the last row
            gamePhase = .lost
        }
    }

    // MARK: - Sharing

    /// Generates the Wordle summary text for sharing.
    func makeShareSummary() -> String {
        var lines: [String] = []

        // Top line: "Wordle {days_since_launch} {attempts}/6"
        let attempts = gamePhase == .won ? String(submittedRowsCount) : "X"
        lines.append("Wordle \(daysSinceLaunch) \(attempts)/6")

        // Blank line
        lines.append("")

        // Emoji grid for submitted rows
        for rowIndex in 0..<submittedRowsCount {
            var rowEmojis = ""
            for col in 0..<5 {
                let tile = board[rowIndex][col]
                switch tile.result {
                case .correct:
                    rowEmojis += "🟩"
                case .present:
                    rowEmojis += "🟨"
                case .miss, .none:
                    rowEmojis += "⬜"
                }
            }
            lines.append(rowEmojis)
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Persistence

    /// Persists the current state if the game is still in progress.
    func persistIfNeeded() {
        guard gamePhase == .playing || gamePhase == .revealing else { return }

        var keyboardStatusesDict: [String: KeyStatus] = [:]
        for (char, status) in keyboardStatuses {
            keyboardStatusesDict[String(char)] = status
        }

        let state = PersistedGameState(
            printDate: printDate,
            daysSinceLaunch: daysSinceLaunch,
            board: board,
            currentRowIndex: currentRowIndex,
            currentColIndex: currentColIndex,
            keyboardStatuses: keyboardStatusesDict,
            phase: gamePhase.rawValue,
            submittedRowsCount: submittedRowsCount
        )

        GamePersistence.save(state)
    }

    /// Clears the persisted state (called when game ends).
    func clearPersistedState() {
        GamePersistence.clear()
    }

    // MARK: - Helpers

    private func resetBoard() {
        board = Array(repeating: Array(repeating: Tile(), count: 5), count: 6)
        currentRowIndex = 0
        currentColIndex = 0
        keyboardStatuses = [:]
        submittedRowsCount = 0
    }
}
