//
//  XYPad.swift
//  Bleeple
//
//  Created by Corné on 8/15/24.
//

import SwiftUI

struct XYPad: View {
    @Environment(\.color) private var color
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
                                .onChanged { drag in
                                    let position = getPosition(for: drag.location, in: geometry.size)
                                    viewModel.damping = position.x / geometry.size.width
                                    viewModel.tone = position.y / geometry.size.height
                                }
                        )
                        .contentShape(Rectangle())
                        .onTapGesture { location in
                            let position = getPosition(for: location, in: geometry.size)
                            viewModel.damping = position.x / geometry.size.width
                            viewModel.tone = position.y / geometry.size.height
                        }

                    Circle()
                        .foregroundColor(color)
                        .frame(width: circleSize, height: circleSize)
                        .position(getPosition(in: geometry.size))
                        // TODO: see if we can make this nicer
                        .animation(.bouncy(duration: 0.5), value: viewModel.damping)
                        .animation(.bouncy(duration: 0.5), value: viewModel.tone)
                }
            }
        }
    }
    
    private func getPosition(in size: CGSize) -> CGPoint {
        CGPoint(
            x: viewModel.damping * size.width,
            y: viewModel.tone * size.height
        )
    }

    private func getPosition(for location: CGPoint, in size: CGSize) -> CGPoint {
        let x = min(max(location.x, circleSize / 2), size.width - circleSize / 2)
        let y = min(max(location.y, circleSize / 2), size.height - circleSize / 2)
        return CGPoint(x: x, y: y)
    }
}
