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

            // Bottom row
            HStack(spacing: 4) {
                // ENTER key
                SpecialKeyButton(label: "ENTER") {
                    viewModel.handleKeyPress("ENTER")
                }

                ForEach(bottomRow, id: \.self) { letter in
                    KeyButton(
                        label: String(letter),
                        status: viewModel.keyboardStatuses[letter] ?? .unknown
                    ) {
                        viewModel.handleKeyPress(String(letter))
                    }
                }

                // DELETE key
                SpecialKeyButton(label: "⌫") {
                    viewModel.handleKeyPress("DELETE")
                }
            }

            // Space bar (wide, minimal for MVP)
            Button(action: {
                // For MVP, space bar can trigger submit when 5 letters are present
                if viewModel.currentColIndex == 5 {
                    viewModel.handleKeyPress("ENTER")
                }
            }) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 40)
            }
            .padding(.horizontal, 4)
        }
        .padding()
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
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(textColor)
                .frame(width: 32, height: 42)
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
            return Color.yellow
        case .correct:
            return Color.green
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
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
                .frame(width: 55, height: 42)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(6)
        }
    }
}
