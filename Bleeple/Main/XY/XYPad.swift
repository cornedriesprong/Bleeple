//
//  XYPad.swift
//  Bleeple
//
//  Created by Corné on 8/15/24.
//

import SwiftUI

struct XYPad: View {
    @Environment(\.color) private var color
    @State private var position: CGPoint = .zero
    @State private var containerSize: CGSize = .zero
    @Binding var viewModel: MainView.ViewModel

    private let circleSize: CGFloat = 22

    var body: some View {
        VStack {
            GeometryReader { geometry in
                ZStack {
                    Rectangle()
                        .foregroundColor(color.opacity(0.1))
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    position = getPosition(for: value.location, in: geometry.size)
                                }
                        )
                        .contentShape(Rectangle())
                        .onTapGesture { location in
                            position = getPosition(for: location, in: geometry.size)
                        }

                    Circle()
                        .foregroundColor(color)
                        .frame(width: circleSize, height: circleSize)
                        .position(position)
                        .animation(.bouncy(duration: 0.2), value: position)
                }
                .onAppear {
                    // no animation on initial positioning
                    withAnimation(.linear(duration: 0)) {
                        position = CGPoint(
                            x: viewModel.damping * geometry.size.width,
                            y: viewModel.tone * geometry.size.height
                        )
                    }
                }
                .onChange(of: position) { _, newValue in
                    viewModel.damping = newValue.x / geometry.size.width
                    viewModel.tone = newValue.y / geometry.size.height
                }
            }
        }
    }

    private func getPosition(for location: CGPoint, in size: CGSize) -> CGPoint {
        let x = min(max(location.x, circleSize / 2), size.width - circleSize / 2)
        let y = min(max(location.y, circleSize / 2), size.height - circleSize / 2)
        return CGPoint(x: x, y: y)
    }
}
