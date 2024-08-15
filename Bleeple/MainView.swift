//
//  ContentView.swift
//  Bleeple
//
//  Created by Corné on 7/24/24.
//

import SwiftUI

struct MainView: View {
    
    enum Mode: String, CaseIterable {
        case grid, xy
    }
    
    @Environment(\.color) private var color
    @State private var viewModel = ViewModel()
    @State private var isPlaying = false
    @State private var mode: Mode = .xy

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
                .onChange(of: viewModel.damping) { _, newValue in
                    viewModel.setParameter(.cutoff, value: newValue)
                }
                .tint(color)
                
                Slider(value: $viewModel.delay) {
                    Text("delay")
                        .fontDesign(.monospaced)
                        .frame(width: 66, alignment: .leading)
                }
                .tint(color)
                .onChange(of: viewModel.delay) { _, newValue in
//                    viewModel.setParameter(.cutoff, value: newValue)
                }
            }
            HStack(spacing: 66) {
                Slider(value: $viewModel.tone) {
                    Text("tone")
                        .fontDesign(.monospaced)
                        .frame(width: 66, alignment: .leading)
                }
                .onChange(of: viewModel.tone) { _, newValue in
                    viewModel.setParameter(.q, value: newValue)
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
    }
    
    var xy: some View {
        XYPad()
    }

    var body: some View {
        ZStack {
            VStack {
                topBar
                
                parameterSliders
                
                Picker(selection: $mode) {
                    ForEach(Mode.allCases, id: \.self) {
                        Text($0.rawValue)
                    }
                } label: {
                    Text("mode")
                        .fontDesign(.monospaced)
                }
                .pickerStyle(.segmented)
                .padding()

                
                switch mode {
                case .grid:
                    grid
                case .xy:
                    xy
                }
            }
        }
    }
}

#Preview {
    MainView()
}
