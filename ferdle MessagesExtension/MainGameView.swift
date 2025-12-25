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

                // Show overlay when space is constrained and no dialog
                if isSpaceConstrained && !showDialog {
                    CompactOverlay()
                        .transition(.opacity)
                }

                // Game end overlay
                if showDialog {
                    ZStack {
                        // Translucent background over the game grid
                        Color.black.opacity(0.4)
                            .edgesIgnoringSafeArea(.all)

                        // Dialog - sized to fit available space
                        GameEndView(
                            viewModel: viewModel,
                            onShare: onShare,
                            onRequestExpansion: onRequestExpansion,
                            availableWidth: geometry.size.width,
                            availableHeight: availableHeight
                        )
                    }
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: showDialog)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeInOut(duration: 0.3), value: showKeyboard)
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
    let availableWidth: CGFloat
    let availableHeight: CGFloat
    @State private var timeUntilMidnight: String = ""
    @State private var isNewWordAvailable: Bool = false

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        // Calculate responsive sizing
        let isCompact = availableHeight < 400
        let contentPadding: CGFloat = isCompact ? 20 : 32
        let outerPadding: CGFloat = isCompact ? 16 : 40
        let maxDialogWidth: CGFloat = min(availableWidth - (outerPadding * 2), 400)

        VStack(spacing: isCompact ? 12 : 20) {
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
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.bottom, isCompact ? 4 : 8)

            Text(viewModel.gamePhase == .won ? "You Won!" : "Game Over")
                .font(isCompact ? .title : .largeTitle)
                .fontWeight(.bold)

            if viewModel.gamePhase == .lost {
                VStack(spacing: isCompact ? 4 : 8) {
                    Text("The word was:")
                        .font(isCompact ? .subheadline : .headline)
                    Text(viewModel.solution)
                        .font(isCompact ? .title2 : .title)
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
                .font(isCompact ? .body : .headline)
                .foregroundColor(.white)
                .padding(.horizontal, isCompact ? 20 : 24)
                .padding(.vertical, isCompact ? 10 : 12)
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

    private func resetGame() {
        viewModel.resetGame()
        // Request expansion if in compact mode
        if availableHeight < 400 {
            onRequestExpansion()
        }
    }
}
