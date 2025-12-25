//
//  MainGameView.swift
//  ferdle MessagesExtension
//
//  Main game UI composition: BoardView + KeyboardView + end-game overlay.
//

import SwiftUI
import Combine

struct MainGameView: View {
    @ObservedObject var viewModel: GameViewModel
    let isCompact: Bool
    let isTransitioning: Bool
    let onShare: (String) -> Void

    var body: some View {
        let showDialog = viewModel.gamePhase == .won || viewModel.gamePhase == .lost
        let hideKeyboard = isCompact || isTransitioning || showDialog

        ZStack {
            // Main layout - board and keyboard stacked vertically
            VStack(spacing: 0) {
                // Board - centered in available space
                Spacer()
                BoardView(viewModel: viewModel, isCompact: isCompact)
                Spacer()

                // Keyboard area - hide when dialog is showing or in compact/transitioning
                if !hideKeyboard {
                    KeyboardView(viewModel: viewModel)
                        .transition(.opacity)
                }
            }

            // Compact mode overlay with Play/Resume button (hidden when dialog showing)
            if isCompact && !showDialog {
                CompactOverlay()
            }

            // Game end overlay
            if showDialog {
                ZStack {
                    if isCompact {
                        // Translucent background in compact mode
                        Color.black.opacity(0.3)
                            .edgesIgnoringSafeArea(.all)
                    }

                    if isCompact {
                        // In compact mode, show dialog with padding for translucent background
                        GameEndView(viewModel: viewModel, onShare: onShare)
                            .padding(16)
                    } else {
                        // In expanded mode, show dialog normally
                        GameEndView(viewModel: viewModel, onShare: onShare)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct CompactOverlay: View {
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)

            Image(systemName: "play.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.8))
        }
        .contentShape(Rectangle())
    }
}

struct GameEndView: View {
    @ObservedObject var viewModel: GameViewModel
    let onShare: (String) -> Void
    @State private var timeUntilMidnight: String = ""
    @State private var isNewWordAvailable: Bool = false

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 20) {
            // Header with Reset button and Timer
            HStack {
                Button(action: resetGame) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title2)
                        .foregroundColor(.primary)
                        .padding(8)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(Circle())
                }

                Spacer()

                Text(isNewWordAvailable ? "New word available!" : timeUntilMidnight)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(isNewWordAvailable ? .green : .secondary)
            }
            .padding(.bottom, 8)

            Text(viewModel.gamePhase == .won ? "You Won!" : "Game Over")
                .font(.largeTitle)
                .fontWeight(.bold)

            if viewModel.gamePhase == .lost {
                VStack(spacing: 8) {
                    Text("The word was:")
                        .font(.headline)
                    Text(viewModel.solution)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0.42, green: 0.64, blue: 0.31))
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
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.systemBackground))
                .shadow(radius: 20)
        )
        .padding(40)
        .onAppear(perform: updateTimer)
        .onReceive(timer) { _ in
            updateTimer()
        }
    }

    private func updateTimer() {
        let now = Date()
        let calendar = Calendar.current

        // Get midnight of the next day
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.day! += 1

        if let midnight = calendar.date(from: components) {
            let interval = midnight.timeIntervalSince(now)

            if interval <= 0 {
                isNewWordAvailable = true
                timeUntilMidnight = "New word available!"
            } else {
                isNewWordAvailable = false
                let hours = Int(interval) / 3600
                let minutes = (Int(interval) % 3600) / 60
                let seconds = Int(interval) % 60
                timeUntilMidnight = String(format: "%d:%02d:%02d until new daily word", hours, minutes, seconds)
            }
        }
    }

    private func resetGame() {
        viewModel.resetGame()
    }
}
