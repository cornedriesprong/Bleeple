//
//  TapGrid.swift
//  Bleeple
//
//  Created by Corné on 8/19/24.
//

import SwiftUI

struct TapGrid: View {
    @Environment(\.color) private var color

    private let rows = Array(repeating: GridItem(.flexible(minimum: 44), spacing: 0.5), count: 4)

    var body: some View {
        Grid(horizontalSpacing: 0.5, verticalSpacing: 0.5) {
            ForEach(0 ..< 8) { _ in
                GridRow {
                    ForEach(0 ..< 8) { _ in
                        Rectangle()
                            .fill(color.opacity(0.2))
                            .padding(0.5)
                    }
                }
            }
        }
        .padding(0.5)
    }
}
