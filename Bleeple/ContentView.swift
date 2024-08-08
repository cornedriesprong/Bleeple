//
//  ContentView.swift
//  Bleeple
//
//  Created by Corné on 7/24/24.
//

import SwiftUI

struct ColorTheme: EnvironmentKey {
    static let defaultValue: Color = .red
}

extension EnvironmentValues {
    var color: Color {
        get { self[ColorTheme.self] }
        set { self[ColorTheme.self] = newValue }
    }
}

struct TopButton: View {
    @State private var isHovering = false
    
    let imageName: String
    let handler: () -> Void
    
    var body: some View {
        Image(systemName: imageName)
            .onTapGesture {
                handler()
            }
            .opacity(isHovering ? 1.0 : 0.5)
            .scaleEffect(isHovering ? 1.2 : 1.0)
            .onHover { hovering in
                isHovering = hovering
            }
            .animation(.easeInOut, value: isHovering)
    }
}

struct ContentView: View {
    @Environment(\.color) var color
    let engine = AudioEngine()
    @State var grid = Array(repeating: Array(repeating: false, count: 16), count: 8)
    @State private var isPlaying = false
    @State private var damping: Double = 0.5
    @State private var tone: Double = 0.5
    @State private var reverb: Double = 0.5
    private let major = [0, 2, 4, 5, 7, 9, 11, 12]
    
    
    var body: some View {
        ZStack {
            VStack {
                HStack(spacing: 22) {
                    TopButton(imageName: "clear") {
                        engine.clearEvents()
                        clear()
                    }
                    .keyboardShortcut("c", modifiers: [.command])
                    
                    TopButton(imageName: "dice") {
                        print("randomize")
                    }
                    
                    TopButton(imageName: isPlaying ? "stop.fill" : "play.fill") {
                        isPlaying.toggle()
                    }
                    .keyboardShortcut(.space)
                    
                    TopButton(imageName: "arrow.uturn.backward") {
                        print("undo")
                    }
                    
                    TopButton(imageName: "arrow.uturn.forward") {
                        print("redo")
                    }
                }
                .padding(.top)
                .padding(.horizontal)
                
                VStack {
                    HStack(spacing: 66) {
                        Slider(value: $damping) {
                            Text("damping")
                                .fontDesign(.monospaced)
                                .frame(width: 66, alignment: .leading)
                        }
                        .tint(color)
                        
                        Slider(value: $tone) {
                            Text("delay")
                                .fontDesign(.monospaced)
                                .frame(width: 66, alignment: .leading)
                        }
                        .tint(color)
                    }
                    HStack(spacing: 66) {
                        Slider(value: $reverb) {
                            Text("tone")
                                .fontDesign(.monospaced)
                                .frame(width: 66, alignment: .leading)
                        }
                        .tint(color)
                        
                        Slider(value: $reverb) {
                            Text("reverb")
                                .fontDesign(.monospaced)
                                .frame(width: 66, alignment: .leading)
                        }
                        .tint(color)
                    }
                }
                .padding()
                
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
            }
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
    
    private func clear() {
        for (x, row) in grid.enumerated() {
            for (y, isOn) in row.enumerated() where isOn {
                grid[x][y] = false
            }
        }
    }
}

#Preview {
    ContentView()
}
