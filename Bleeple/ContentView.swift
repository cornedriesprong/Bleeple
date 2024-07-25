//
//  ContentView.swift
//  Bleeple
//
//  Created by Corné on 7/24/24.
//

import SwiftUI

struct ContentView: View {
    let engine = AudioEngine()
    @State var grid = Array(repeating: Array(repeating: false, count: 16), count: 8)
    private let major = [0, 2, 4, 5, 7, 9, 11, 12]
    
    var body: some View {
        Grid(horizontalSpacing: 1, verticalSpacing: 1) {
            ForEach(0..<grid.count) { row in
                GridRow {
                    ForEach(0..<grid[row].count) { column in
                        let onOff = grid[row][column]
                        Rectangle()
                            .foregroundStyle(.red)
                            .opacity(onOff ? 1 : 0.1)
                            .onTapGesture {
                                grid[row][column].toggle()
                            }
                    }
                }
            }
        }
        .padding(1)
        .onChange(of: grid) { _, _ in
            engine.clearEvents()
            for (x, row) in grid.enumerated() {
                for (y, isOn) in row.enumerated() where isOn {
                    engine.addEvent(step: y, pitch: major.reversed()[x] + 52)
                }
            }
        }
    }
}

//extension ContentView {
//    struct ViewModel {
//        var pattern: []
//    }
//}

#Preview {
    ContentView()
}
