//
//  FerdleRootView.swift
//  ferdle MessagesExtension
//
//  Root SwiftUI view: loading state, error state, and main game UI.
//

import SwiftUI
import Messages
import Combine

struct FerdleRootView: View {
    @StateObject private var viewModel = GameViewModel()
    @State private var loadingState: LoadingState = .loading
    @State private var errorMessage: String?
    @State private var isCompact: Bool = false
    @State private var isTransitioning: Bool = false

    let presentationStylePublisher: AnyPublisher<MSMessagesAppPresentationStyle, Never>
    let onShare: (String) -> Void
    let onRequestExpansion: () -> Void

    enum LoadingState {
        case loading
        case loaded
        case error
    }

    var body: some View {
        ZStack {
            switch loadingState {
            case .loading:
                ProgressView("Loading today's puzzle...")
                    .font(.headline)

            case .loaded:
                MainGameView(
                    viewModel: viewModel,
                    isCompact: isCompact,
                    isTransitioning: isTransitioning,
                    onShare: onShare
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    if isCompact {
                        onRequestExpansion()
                    }
                }

            case .error:
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)

                    Text("Failed to load puzzle")
                        .font(.headline)

                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    Button(action: {
                        loadPuzzle()
                    }) {
                        Text("Retry")
                            .fontWeight(.semibold)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding()
            }
        }
        .onAppear {
            loadPuzzle()
        }
        .onReceive(presentationStylePublisher) { style in
            let targetCompact = (style == .compact)

            // Only handle transitions when state actually changes
            guard targetCompact != isCompact else { return }

            if targetCompact {
                // Transitioning to compact - hide keyboard immediately
                isTransitioning = true
                // Then complete the compact transition
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isCompact = true
                    isTransitioning = false
                }
            } else {
                // Transitioning to expanded - keep keyboard hidden during transition
                isTransitioning = true
                isCompact = false
                // Show keyboard almost immediately (very brief delay for transition to start)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    withAnimation(.easeIn(duration: 0.1)) {
                        isTransitioning = false
                    }
                }
            }
        }
    }

    private func loadPuzzle() {
        loadingState = .loading
        errorMessage = nil

        Task {
            do {
                let puzzle = try await WordleAPI.fetchPuzzle()
                await MainActor.run {
                    viewModel.configureForToday(puzzle: puzzle)
                    loadingState = .loaded
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    loadingState = .error
                }
            }
        }
    }
}
