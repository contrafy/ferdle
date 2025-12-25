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

    let presentationStylePublisher: AnyPublisher<MSMessagesAppPresentationStyle, Never>
    let onShare: (String) -> Void

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
                MainGameView(viewModel: viewModel, isCompact: isCompact, onShare: onShare)

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
            isCompact = (style == .compact)
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
