//
//  ContentView.swift
//  Bleeple
//
//  Created by Corné on 7/24/24.
//

import SwiftUI

let colors: [Color] = [
    .cp3Red,
    .cp3Yellow,
    .cp3Turquoise,
    .cp3Magenta,
    .cp3Ocean,
    .cp3Lila,
    .cp3Blue,
    .cp3Lime,
    .cp3Cyan,
    .cp3Orange,
    .cp3Purple,
    .cp3Green,
]

struct MainView: View {
    // MARK: - Types
    
    enum Mode: String, CaseIterable {
        case roll, grid, xy
    }
    
    enum Section: Int, CaseIterable, CustomStringConvertible {
        case seq, dco, filter, arp, fx, config
        
        var description: String {
            switch self {
            case .seq: "seq"
            case .dco: "dco"
            case .filter: "filter"
            case .arp: "arp"
            case .fx: "fx"
            case .config: "config"
            }
        }
    }

    // MARK: - Properties
    
    @State private var viewModel = ViewModel.shared
    @State private var mode: Mode = .grid
    @State private var section: Section = .dco
    @State private var isShiftPressed = false
    
    // MARK: - View

    var topBar: some View {
        HStack(spacing: 22) {
            Button {
                viewModel.clear()
            } label: {
                Image(systemName: "clear")
            }
            
            Button {
                print("randomize")
            } label: {
                Image(systemName: "dice")
            }
            
            Button {
                viewModel.isPlaying.toggle()
            } label: {
                Image(systemName: viewModel.isPlaying ? "stop.fill" : "play.fill")
            }
            
            Button {
                viewModel.undo()
            } label: {
                Image(systemName: "arrow.uturn.backward")
            }
            
            Button {
                viewModel.redo()
            } label: {
                Image(systemName: "arrow.uturn.forward")
            }
        }
        .padding(.top)
        .padding(.horizontal)
    }
    
    var controls: some View {
        VStack {
            HStack(spacing: 20) {
                ForEach(Section.allCases, id: \.self) { section in
                    Button {
                        self.section = section
                    } label: {
                        Text(section.description.uppercased())
                            .opacity(self.section == section ? 1.0 : 0.5)
                    }
                }
            }
            .padding(.top, 20)
            .tint(.primary)
            
            Group {
                switch section {
                case .seq:
                    EmptyView()
                case .dco:
                    Grid {
                        GridRow {
                            Knob(
                                text: "osc1 freq \(Int(viewModel.carrierFreq)) Hz",
                                value: $viewModel.carrierFreq,
                                range: 0.0..<10000.0,
                                defaultValue: 440.0,
                                curve: 4
                            )
                            Knob(
                                text: "osc2 freq \(Int(viewModel.modFreq)) Hz",
                                value: $viewModel.modFreq,
                                range: 0.0..<10000.0,
                                defaultValue: 660.0,
                                curve: 4
                            )
                        }
                        GridRow {
                            Knob(
                                text: "fm amount \(String(format: "%.2f", viewModel.fmAmount))",
                                value: $viewModel.fmAmount,
                                range: 0.0..<1.0,
                                defaultValue: 0.5
                            )
                            Knob(
                                text: "mod amount \(String(format: "%.2f", viewModel.modAmount))",
                                value: $viewModel.modAmount,
                                range: 0.0..<3.0,
                                defaultValue: 0.5,
                                curve: 2
                            )
                        }
                    }
                case .filter:
                    Grid {
                        GridRow {
                            Knob(
                                text: "cutoff \(Int(viewModel.cutoff)) Hz",
                                value: $viewModel.cutoff,
                                range: 50.0..<10000.0,
                                defaultValue: 5000.0,
                                curve: 4
                            )
                            Knob(
                                text: "resonance \(String(format: "%.2f", viewModel.resonance))",
                                value: $viewModel.resonance,
                                range: 0.0..<10.0,
                                defaultValue: 0.717
                            )
                        }
                    }
                case .arp:
                    EmptyView()
                case .fx:
                    EmptyView()
                case .config:
                    EmptyView()
                }
            }
            
            .padding()
        }
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
    
    var trackSelection: some View {
        HStack(spacing: 0) {
            ForEach(0 ..< 6) { index in
                Button {
                    viewModel.selectedTrack = index
                } label: {
                    let isSelected = index == viewModel.selectedTrack
                    Text("\(index + 1)")
                        .foregroundColor(isSelected ? .black : colors[index])
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(colors[index].opacity(isSelected ? 1.0 : 0.1).gradient)
                }
            }
        }
        .frame(height: 44)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    controls
                    
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
                    //                trackSelection
                }
            }
            .environment(\.color, colors[section.rawValue])
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    topBar
                        .tint(.primary)
                }
            }
        }
    }
}

#Preview {
    MainView()
}
