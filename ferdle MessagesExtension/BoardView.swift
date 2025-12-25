//
//  BoardView.swift
//  ferdle MessagesExtension
//
//  Renders the 6x5 tile grid with animations driven by Tile state.
//

import SwiftUI

struct BoardView: View {
    @ObservedObject var viewModel: GameViewModel
    let isCompact: Bool

    var body: some View {
        VStack(spacing: isCompact ? 3 : 6) {
            ForEach(0..<6, id: \.self) { row in
                HStack(spacing: isCompact ? 3 : 6) {
                    ForEach(0..<5, id: \.self) { col in
                        TileView(tile: viewModel.board[row][col], isCompact: isCompact)
                    }
                }
            }
        }
        .padding(isCompact ? 8 : 16)
        .frame(maxWidth: .infinity)
    }
}

struct TileView: View {
    let tile: Tile
    let isCompact: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: isCompact ? 2 : 4)
                .fill(tileBackgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: isCompact ? 2 : 4)
                        .stroke(tileBorderColor, lineWidth: isCompact ? 1 : 2)
                )

            // Hide letters in compact mode
            if !isCompact {
                Text(tile.letter)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(tileTextColor)
            }
        }
        .frame(width: isCompact ? 24 : 60, height: isCompact ? 24 : 60)
        .animation(.easeInOut(duration: 0.25), value: tile.isRevealed)
    }

    private var tileBackgroundColor: Color {
        guard tile.isRevealed, let result = tile.result else {
            return tile.letter.isEmpty ? Color.clear : Color.primary.opacity(0.05)
        }

        switch result {
        case .correct:
            return Color(red: 0.42, green: 0.64, blue: 0.31) // Darker, duller green
        case .present:
            return Color(red: 0.72, green: 0.65, blue: 0.26) // Darker, duller yellow
        case .miss:
            return Color.gray
        }
    }

    private var tileBorderColor: Color {
        if tile.letter.isEmpty {
            return Color.gray.opacity(0.3)
        }
        if tile.isRevealed {
            return Color.clear
        }
        return Color.gray.opacity(0.6)
    }

    private var tileTextColor: Color {
        if tile.isRevealed && tile.result != nil {
            return .white
        }
        return .primary
    }
}
