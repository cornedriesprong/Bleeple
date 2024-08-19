//
//  TapGrid.swift
//  Bleeple
//
//  Created by Corné on 8/19/24.
//

import SwiftUI

struct TapGrid: View {
    private static let gridLength = 12
    
    @Environment(\.color) private var color
    @State private var tapped = Array(
        repeating: Array(repeating: false, count: TapGrid.gridLength),
        count: TapGrid.gridLength
    )

    private let rows = Array(repeating: GridItem(.flexible(minimum: 44), spacing: 0.5), count: 4)

    var body: some View {
        Grid(horizontalSpacing: 0.5, verticalSpacing: 0.5) {
            ForEach(0 ..< TapGrid.gridLength) { row in
                GridRow {
                    ForEach(0 ..< TapGrid.gridLength) { column in
                        Rectangle()
                            .fill(color.opacity(tapped[row][column] ? 1.0 : 0.2))
                            .padding(0.5)
                            .onLongPressGesture(minimumDuration: 0) {
                                let pitchCount = TapGrid.gridLength * TapGrid.gridLength
                                let pitch = pitchCount - ((row * TapGrid.gridLength) - column)
                                note_on(Int8(pitch), 100, 0.5, 0.5)
                                
                                tapped[row][column] = true
                                withAnimation(.easeOut(duration: 0.4)) {
                                    tapped[row][column] = false
                                }
                            }
                    }
                }
            }
        }
        .padding(0.5)
    }
    
}
