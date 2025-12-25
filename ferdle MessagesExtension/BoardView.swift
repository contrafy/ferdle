//
//  BoardView.swift
//  ferdle MessagesExtension
//
//  Renders the 6x5 tile grid with animations driven by Tile state.
//  Dynamically sizes based on available space.
//

import SwiftUI

struct BoardView: View {
    @ObservedObject var viewModel: GameViewModel
    let availableHeight: CGFloat

    var body: some View {
        GeometryReader { geometry in
            // Calculate tile size based on available height
            // Reserve space for padding and spacing
            let totalPadding = padding * 2
            let totalSpacing = spacing * 5 // 5 gaps between 6 rows
            let availableForTiles = max(0, availableHeight - totalPadding - totalSpacing)
            let heightBasedTileSize = availableForTiles / 6

            // Also constrain by width to prevent overflow
            let availableWidth = geometry.size.width - totalPadding
            let widthBasedTileSize = (availableWidth - (spacing * 4)) / 5 // 4 gaps between 5 columns

            // Use the smaller of the two to ensure it fits
            let calculatedTileSize = min(heightBasedTileSize, widthBasedTileSize, 60) // Max 60pt in expanded

            VStack(spacing: spacing) {
                ForEach(0..<6, id: \.self) { row in
                    HStack(spacing: spacing) {
                        ForEach(0..<5, id: \.self) { col in
                            TileView(tile: viewModel.board[row][col], tileSize: calculatedTileSize)
                        }
                    }
                }
            }
            .padding(padding)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeInOut(duration: 0.3), value: calculatedTileSize)
        }
    }

    // Spacing and padding scale with tile size
    private var spacing: CGFloat {
        let tileSize = max(0, availableHeight - padding * 2) / 6
        return tileSize < 35 ? 3 : 6
    }

    private var padding: CGFloat {
        let tileSize = max(0, availableHeight) / 6
        return tileSize < 35 ? 8 : 16
    }
}

struct TileView: View {
    let tile: Tile
    let tileSize: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(tileBackgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(tileBorderColor, lineWidth: borderWidth)
                )

            // Always render text, but fade it out based on size
            Text(tile.letter)
                .font(.system(size: fontSize, weight: .bold))
                .foregroundColor(tileTextColor)
                .opacity(textOpacity)
        }
        .frame(width: tileSize, height: tileSize)
        .animation(.easeInOut(duration: 0.3), value: tileSize)
        .animation(.easeInOut(duration: 0.25), value: tile.isRevealed)
    }

    // Dynamic styling based on tile size
    private var cornerRadius: CGFloat {
        tileSize < 35 ? 2 : 4
    }

    private var borderWidth: CGFloat {
        tileSize < 35 ? 1 : 2
    }

    private var fontSize: CGFloat {
        // Scale font size with tile size
        min(32, tileSize * 0.5)
    }

    private var textOpacity: Double {
        // Fade out text as tiles get smaller
        if tileSize > 50 {
            return 1.0
        } else if tileSize > 35 {
            return Double((tileSize - 35) / 15)
        } else {
            return 0
        }
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
