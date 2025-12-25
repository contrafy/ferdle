//
//  MainGameView.swift
//  ferdle MessagesExtension
//
//  Main game UI composition: BoardView + KeyboardView + end-game overlay.
//

import SwiftUI

struct MainGameView: View {
    @ObservedObject var viewModel: GameViewModel
    let isCompact: Bool
    let onShare: (String) -> Void

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Board
                Spacer()
                BoardView(viewModel: viewModel, isCompact: isCompact)
                Spacer()

                // Keyboard (hidden in compact mode)
                if !isCompact {
                    KeyboardView(viewModel: viewModel)
                }
            }

            // Game end overlay (hidden in compact mode)
            if !isCompact && (viewModel.gamePhase == .won || viewModel.gamePhase == .lost) {
                GameEndView(viewModel: viewModel, onShare: onShare)
            }
        }
    }
}

struct GameEndView: View {
    @ObservedObject var viewModel: GameViewModel
    let onShare: (String) -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text(viewModel.gamePhase == .won ? "🎉 You Won!" : "Game Over")
                .font(.largeTitle)
                .fontWeight(.bold)

            if viewModel.gamePhase == .lost {
                VStack(spacing: 8) {
                    Text("The word was:")
                        .font(.headline)
                    Text(viewModel.solution)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }

            Button(action: {
                let summary = viewModel.makeShareSummary()
                onShare(summary)
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Results")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.blue)
                .cornerRadius(12)
            }

            Text("Tap to insert summary in conversation")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.systemBackground))
                .shadow(radius: 20)
        )
        .padding(40)
    }
}
