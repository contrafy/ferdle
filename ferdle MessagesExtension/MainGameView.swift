//
//  MainGameView.swift
//  ferdle MessagesExtension
//
//  Main game UI composition: BoardView + KeyboardView + end-game overlay.
//  Uses dynamic layout based on available screen space.
//

import SwiftUI
import Combine

struct MainGameView: View {
    @ObservedObject var viewModel: GameViewModel
    let onShare: (String) -> Void
    let onRequestExpansion: () -> Void

    @State private var isResetting: Bool = false

    var body: some View {
        GeometryReader { geometry in
            let availableHeight = geometry.size.height
            let showDialog = viewModel.gamePhase == .won || viewModel.gamePhase == .lost

            // Determine layout based on available space
            // If we have less than 400pt height, we're in compact mode
            let isSpaceConstrained = availableHeight < 400
            let showKeyboard = !isSpaceConstrained && !showDialog

            ZStack {
                // Main layout - board and keyboard stacked vertically
                VStack(spacing: 0) {
                    // Board - centered in available space
                    Spacer(minLength: 0)
                    BoardView(viewModel: viewModel, availableHeight: showKeyboard ? availableHeight - 220 : availableHeight)
                    Spacer(minLength: 0)

                    // Keyboard area - pinned to bottom
                    if showKeyboard {
                        KeyboardView(viewModel: viewModel)
                            .transition(.opacity)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .zIndex(0)

                // Show overlay when space is constrained and no dialog (but not when resetting)
                if isSpaceConstrained && !showDialog && !isResetting {
                    CompactOverlay()
                        .transition(.opacity)
                }

                // Game end overlay with translucent background
                if showDialog {
                    
                    // Dialog - sized to fit available space
                    GameEndView(
                        viewModel: viewModel,
                        onShare: onShare,
                        onRequestExpansion: onRequestExpansion,
                        onReset: {
                            handleReset(isCompact: isSpaceConstrained)
                        },
                        availableWidth: geometry.size.width,
                        isCompact: isSpaceConstrained
                    )
                    // .transition(.opacity)
                    .zIndex(2)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeInOut(duration: 0.3), value: showDialog)
            .animation(.easeInOut(duration: 0.3), value: showKeyboard)
        }
    }

    private func handleReset(isCompact: Bool) {
        if isCompact {
            // Set resetting flag to prevent CompactOverlay flash
            isResetting = true
            // Request expansion first
            onRequestExpansion()
            // Reset after a brief delay to allow expansion to start
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                viewModel.resetGame()
                // Clear resetting flag after expansion completes
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    isResetting = false
                }
            }
        } else {
            // In expanded mode, reset immediately
            viewModel.resetGame()
        }
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
    let onRequestExpansion: () -> Void
    let onReset: () -> Void
    let availableWidth: CGFloat
    let isCompact: Bool
    @State private var timeUntilMidnight: String = ""
    @State private var isNewWordAvailable: Bool = false

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        // Calculate responsive sizing - now uses stable isCompact flag
        let contentPadding: CGFloat = 20
        let outerPadding: CGFloat = 16
        let maxDialogWidth: CGFloat = min(availableWidth - (outerPadding * 2), 400)

        VStack(spacing: 20) {
            // Header with Reset button and Timer
            HStack {
                Button(action: onReset) {
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
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.bottom, 8)

            Text(viewModel.gamePhase == .won ? "You Won!" : "Game Over")
                .font(.title)
                .fontWeight(.bold)

            if viewModel.gamePhase == .lost {
                VStack(spacing: 8) {
                    Text("The word was:")
                        .font(.subheadline)
                    Text(viewModel.solution)
                        .font(.title2)
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
        .padding(contentPadding)
        .frame(maxWidth: maxDialogWidth)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.systemBackground))
                .shadow(radius: 20)
        )
        .padding(outerPadding)
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
}
