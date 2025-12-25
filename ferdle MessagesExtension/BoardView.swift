//
//  BoardView.swift
//  ferdle MessagesExtension
//
//  Renders the 6x5 tile grid with animations driven by Tile state.
//

import SwiftUI

struct BoardView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        VStack(spacing: 6) {
            ForEach(0..<6, id: \.self) { row in
                HStack(spacing: 6) {
                    ForEach(0..<5, id: \.self) { col in
                        TileView(tile: viewModel.board[row][col])
                    }
                }
            }
        }
        .padding()
    }
}

struct TileView: View {
    let tile: Tile

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(tileBackgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(tileBorderColor, lineWidth: 2)
                )

            Text(tile.letter)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(tileTextColor)
        }
        .frame(width: 60, height: 60)
        .animation(.easeInOut(duration: 0.25), value: tile.isRevealed)
    }

    private var tileBackgroundColor: Color {
        guard tile.isRevealed, let result = tile.result else {
            return tile.letter.isEmpty ? Color.clear : Color.primary.opacity(0.05)
        }

        switch result {
        case .correct:
            return Color.green
        case .present:
            return Color.yellow
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
