//
//  TapGrid.swift
//  Bleeple
//
//  Created by Corné on 8/19/24.
//

import CP3Music
import SwiftUI

struct TapGrid: View {
    private static let gridLength = 4
    private static let spacing = 0.5

    @Environment(\.color) private var color
    @Environment(\.scale) private var scale

    @State private var tapped = Array(
        repeating: Array(repeating: false, count: TapGrid.gridLength),
        count: TapGrid.gridLength
    )
    @Binding var viewModel: MainView.ViewModel

    private let rows = Array(repeating: GridItem(.flexible(minimum: 44), spacing: 0.5), count: 4)

    var body: some View {
        Grid(horizontalSpacing: TapGrid.spacing, verticalSpacing: TapGrid.spacing) {
            ForEach(0 ..< TapGrid.gridLength) { row in
                GridRow {
                    ForEach(0 ..< TapGrid.gridLength) { column in
                        let pitchCount = TapGrid.gridLength * TapGrid.gridLength
                        let offset = 32
                        let pitch = pitchCount - ((row * TapGrid.gridLength) - column) + offset
                        let isInScale = scale.pitches.map { Int($0.rawValue) }.contains(pitch % 12)
                        let isTapped = tapped[row][column]
                        let isActive = viewModel.activePitches.contains(Int8(pitch))
                        let opacity = getOpacity(isTapped: isTapped, isActive: isActive, isInScale: isInScale)

                        ZStack {
                            Rectangle()
                                .fill(color.opacity(opacity))
                                .padding(0.5)
                                .animation(.easeInOut, value: viewModel.activePitches)
                                .overlay(alignment: .topLeading) {
                                    Text(Pitch(midiNoteNumber: Int8(pitch)).description)
                                        .font(.caption2)
                                        .monospaced()
                                        .padding(4)
                                }
                        }
                        .gesture(
                            LongPressGesture(minimumDuration: 0)
                                .onEnded { _ in
                                    viewModel.noteOn(pitch)

                                    tapped[row][column] = true
                                }
                        )
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 0)
                                .onEnded { _ in
                                    viewModel.noteOff(pitch)

                                    withAnimation(.easeOut(duration: 0.4)) {
                                        tapped[row][column] = false
                                    }
                                }
                        )
                    }
                }
            }
        }
        .padding(0.5)
    }

    func getOpacity(isTapped: Bool, isActive: Bool, isInScale: Bool) -> Double {
        if isTapped || isActive {
            return 1.0
        } else if isInScale {
            return 0.2
        } else {
            return 0.1
        }
    }
}
