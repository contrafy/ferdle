//
//  KeyboardView.swift
//  ferdle MessagesExtension
//
//  Custom keyboard with letter status coloring and special keys.
//

import SwiftUI

struct KeyboardView: View {
    @ObservedObject var viewModel: GameViewModel

    private let topRow = Array("QWERTYUIOP")
    private let middleRow = Array("ASDFGHJKL")
    private let bottomRow = Array("ZXCVBNM")

    var body: some View {
        VStack(spacing: 8) {
            // Top row
            HStack(spacing: 4) {
                ForEach(topRow, id: \.self) { letter in
                    KeyButton(
                        label: String(letter),
                        status: viewModel.keyboardStatuses[letter] ?? .unknown
                    ) {
                        viewModel.handleKeyPress(String(letter))
                    }
                }
            }

            // Middle row
            HStack(spacing: 4) {
                ForEach(middleRow, id: \.self) { letter in
                    KeyButton(
                        label: String(letter),
                        status: viewModel.keyboardStatuses[letter] ?? .unknown
                    ) {
                        viewModel.handleKeyPress(String(letter))
                    }
                }
            }
            .frame(maxWidth: .infinity)

            // Bottom row with letters only
            HStack(spacing: 4) {
                ForEach(bottomRow, id: \.self) { letter in
                    KeyButton(
                        label: String(letter),
                        status: viewModel.keyboardStatuses[letter] ?? .unknown
                    ) {
                        viewModel.handleKeyPress(String(letter))
                    }
                }
            }
            .frame(maxWidth: .infinity)

            // Bottom row: ENTER | SPACE (wide) | BACKSPACE
            HStack(spacing: 4) {
                // ENTER key
                SpecialKeyButton(label: "ENTER") {
                    viewModel.handleKeyPress("ENTER")
                }

                // Space bar (wide, in the middle)
                Button(action: {
                    // For MVP, space bar can trigger submit when 5 letters are present
                    if viewModel.currentColIndex == 5 {
                        viewModel.handleKeyPress("ENTER")
                    }
                }) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 46)
                }

                // DELETE key
                SpecialKeyButton(label: "⌫") {
                    viewModel.handleKeyPress("DELETE")
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.top, 12)
        .padding(.horizontal, 12)
        .glassBackground()
    }
}

struct KeyButton: View {
    let label: String
    let status: KeyStatus
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(textColor)
                .frame(width: 32, height: 46)
                .background(backgroundColor)
                .cornerRadius(6)
        }
    }

    private var backgroundColor: Color {
        switch status {
        case .unknown:
            return Color.gray.opacity(0.2)
        case .miss:
            return Color.gray.opacity(0.5)
        case .present:
            return Color(red: 0.72, green: 0.65, blue: 0.26) // Darker, duller yellow
        case .correct:
            return Color(red: 0.42, green: 0.64, blue: 0.31) // Darker, duller green
        }
    }

    private var textColor: Color {
        switch status {
        case .unknown, .miss:
            return .primary
        case .present, .correct:
            return .white
        }
    }
}

struct SpecialKeyButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            if label == "⌫" {
                Image(systemName: "delete.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 50, height: 46)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(6)
            } else {
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 50, height: 46)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(6)
            }
        }
    }
}
