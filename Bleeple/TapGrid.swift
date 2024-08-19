//
//  TapGrid.swift
//  Bleeple
//
//  Created by Corné on 8/19/24.
//

import SwiftUI
import CP3Music

struct TapGrid: View {
    private static let gridLength = 12
    
    @Environment(\.color) private var color
    @Environment(\.scale) private var scale
    
    @State private var tapped = Array(
        repeating: Array(repeating: false, count: TapGrid.gridLength),
        count: TapGrid.gridLength
    )
    @Binding var viewModel: MainView.ViewModel

    private let rows = Array(repeating: GridItem(.flexible(minimum: 44), spacing: 0.5), count: 4)

    var body: some View {
        Grid(horizontalSpacing: 0.5, verticalSpacing: 0.5) {
            ForEach(0 ..< TapGrid.gridLength) { row in
                GridRow {
                    ForEach(0 ..< TapGrid.gridLength) { column in
                        let pitchCount = TapGrid.gridLength * TapGrid.gridLength
                        let pitch = pitchCount - ((row * TapGrid.gridLength) - column)
                        let isInScale = scale.pitches.map { Int($0.rawValue) }.contains(pitch % 12)
                        
                        Rectangle()
                            .fill(color.opacity(tapped[row][column] ? 1.0 : isInScale ? 0.2 : 0.1))
                            .padding(0.5)
                            .onLongPressGesture(minimumDuration: 0) {
                                viewModel.play(pitch)
                                
                                // animate tap
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
