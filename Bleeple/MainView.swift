//
//  ContentView.swift
//  Bleeple
//
//  Created by Corné on 7/24/24.
//

import SwiftUI

struct MainView: View {
    @Environment(\.color) private var color
    @State private var viewModel = ViewModel()
    @State private var isPlaying = false

    var topBar: some View {
        HStack(spacing: 22) {
            TopButton(imageName: "clear") {
                viewModel.clear()
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
    }
    
    var parameterSliders: some View {
        VStack {
            HStack(spacing: 66) {
                Slider(value: $viewModel.damping) {
                    Text("damping")
                        .fontDesign(.monospaced)
                        .frame(width: 66, alignment: .leading)
                }
                .tint(color)
                
                Slider(value: $viewModel.delay) {
                    Text("delay")
                        .fontDesign(.monospaced)
                        .frame(width: 66, alignment: .leading)
                }
                .tint(color)
            }
            HStack(spacing: 66) {
                Slider(value: $viewModel.tone) {
                    Text("tone")
                        .fontDesign(.monospaced)
                        .frame(width: 66, alignment: .leading)
                }
                .tint(color)
                
                Slider(value: $viewModel.reverb) {
                    Text("reverb")
                        .fontDesign(.monospaced)
                        .frame(width: 66, alignment: .leading)
                }
                .tint(color)
            }
        }
        .padding()
        
    }
    
    var grid: some View {
        PianoRoll(events: $viewModel.events)
//        Grid(horizontalSpacing: 1, verticalSpacing: 1) {
//            ForEach(viewModel.events.indices, id: \.self) { row in
//                GridRow {
//                    ForEach(viewModel.events[row].indices, id: \.self) { column in
//                        CellView(isActive: $viewModel.events[row][column] != nil)
//                    }
//                }
//            }
//        }
//        .onChange(of: viewModel.events) { _, _ in
//            engine.clearEvents()
//            for (x, row) in viewModel.events.enumerated() {
//                for (y, eventOrNil) in row.enumerated() where eventOrNil != nil {
//                    engine.addEvent(step: y, pitch: major.reversed()[x] + 52)
//                }
//            }
//        }
    }
    
    var body: some View {
        ZStack {
            VStack {
                topBar
                
                parameterSliders
                
                grid
            }
        }
    }
}

#Preview {
    MainView()
}
