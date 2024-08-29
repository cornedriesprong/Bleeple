//
//  Knob.swift
//  Bleeple
//
//  Created by Corné on 8/25/24.
//

import SwiftUI

struct Knob: View {
    @Environment(\.color) private var color
    let text: String
    @Binding var value: Double
    
    private let defaultValue = 0.5
    private let thickness = 6.0
    
    @State private var isDragging = false
    @State private var valueOffset = 0.0
    
    var body: some View {
        VStack {
            // knob
            ZStack {
                // background path
                Circle()
                    .trim(from: 0, to: 0.8)
                    .rotation(Angle(degrees: 126))
                    .stroke(style: .init(lineWidth: thickness * 1.5))
                    .foregroundColor(color.opacity(0.15))
                
                Circle()
                    .trim(from: 0, to: CGFloat(value) * 0.8)
                    .rotation(Angle(degrees: 126))
                    .stroke(style: .init(
                        lineWidth: thickness * 1.5))
                    .foregroundColor(color)
            }
            .contentShape(Rectangle())
            .gesture(DragGesture()
                .onChanged { value in
                    let dragFactor = 200.0
                    if !isDragging {
                        isDragging = true
                        valueOffset = self.value * dragFactor
                    }
                    let offsetValue = (value.translation.height * -1) + valueOffset
                    self.value = max(0, min(1, (offsetValue / dragFactor)))
                }
                .onEnded { _ in
                    isDragging = false
                })
            .gesture(TapGesture(count: 2).onEnded { _ in
                self.value = defaultValue
            })
            
            // label
            Text(text).monospaced()
        }
        .padding(.bottom, 20)
    }
}
