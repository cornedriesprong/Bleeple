//
//  ContentView.swift
//  Bleeple
//
//  Created by Corné on 7/24/24.
//

import SwiftUI

struct MainView: View {
    // MARK: - Types
    
    enum Mode: String, CaseIterable {
        case roll, grid, xy
    }
    
    // MARK: - Properties
    
    @Environment(\.color) private var color
    @State private var viewModel = ViewModel.shared
    @State private var isPlaying = false
    @State private var mode: Mode = .grid
    @State private var isShiftPressed = false
    
    // MARK: - View

    var topBar: some View {
        HStack(spacing: 22) {
            Picker(selection: $viewModel.selectedSound) {
                ForEach(PlaitsEngine.allCases.filter { $0.enabled }, id: \.self) {
                    Text("\($0.description)")
                }
            } label: {
                Text("sound")
            }
                         
            TopButton(imageName: "clear") {
                viewModel.clear()
            }
            
            TopButton(imageName: "dice") {
                print("randomize")
            }
            
            TopButton(imageName: isPlaying ? "stop.fill" : "play.fill") {
                isPlaying.toggle()
            }
            .keyboardShortcut(.space)
            
            TopButton(imageName: "arrow.uturn.backward") {
                viewModel.undo()
            }
            
            TopButton(imageName: "arrow.uturn.forward") {
                viewModel.redo()
            }
        }
        .padding(.top)
        .padding(.horizontal)
    }
    
    var parameterSliders: some View {
        Grid {
            GridRow {
                Knob(text: "damping", value: $viewModel.damping)
                Knob(text: "tone", value: $viewModel.tone)
            }
            GridRow {
                Knob(text: "delay", value: $viewModel.delay)
                Knob(text: "reverb", value: $viewModel.reverb)
            }
        }
        .padding()
    }
    
    var grid: some View {
        TapGrid(viewModel: $viewModel)
    }

    var roll: some View {
        ScrollViewReader { proxy in
            ScrollView([.horizontal, .vertical], showsIndicators: true) {
                PianoRoll(viewModel: $viewModel).id("pianoRoll")
            }
            .onAppear {
                // scroll to vertical center
                DispatchQueue.main.async {
                    proxy.scrollTo("pianoRoll", anchor: .center)
                    proxy.scrollTo("pianoRoll", anchor: .leading)
                }
            }
        }
    }
    
    var xy: some View {
        XYPad(viewModel: $viewModel)
    }

    var body: some View {
        ZStack {
            VStack {
                topBar
                
                parameterSliders
                
                Picker("Mode", selection: $mode) {
                    ForEach(Mode.allCases, id: \.self) {
                        Text($0.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .padding()
                
                switch mode {
                case .grid:
                    grid
                case .roll:
                    roll
                case .xy:
                    xy
                }
            }
        }
#if canImport(AppKit)
        .onAppear {
            addKeyboardListeners()
        }
        .onDisappear {
            removeKeyboardListeners()
        }
        .environment(\.isShiftPressed, isShiftPressed)
#endif
    }
    
#if canImport(AppKit)
    private func addKeyboardListeners() {
        NSEvent.addLocalMonitorForEvents(matching: [.flagsChanged]) { event in
            isShiftPressed = event.modifierFlags.contains(.shift)
            return event
        }
    }

    private func removeKeyboardListeners() {
        NSEvent.removeMonitor(self)
    }
#endif
}

#Preview {
    MainView()
}
