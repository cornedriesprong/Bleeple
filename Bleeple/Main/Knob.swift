//
//  Knob.swift
//  Bleeple
//
//  Created by Corné on 8/25/24.
//

import SwiftUI

struct Knob: View {
    @Environment(\.color) private var color
    @Binding var value: Double
    let range: Range<Double>
    let defaultValue: Double
    let text: String
    let curve: Int
    
    private let thickness = 6.0
    
    @State private var internalValue: Double
    @State private var isDragging = false
    @State private var valueOffset = 0.0
    
    init(
        text: String,
        value: Binding<Double>,
        range: Range<Double>,
        defaultValue: Double,
        curve: Int = 1
    ) {
        self.text = text
        self._value = value
        self.range = range
        self.internalValue = Utils.linearToExponential(
            defaultValue / (range.upperBound - range.lowerBound) + range.lowerBound,
            curve: curve
        )
        self.defaultValue = defaultValue
        self.curve = curve
    }
    
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
                    .trim(from: 0, to: CGFloat(internalValue) * 0.8)
                    .rotation(Angle(degrees: 126))
                    .stroke(style: .init(lineWidth: thickness * 1.5))
                    .foregroundColor(color)
            }
            .contentShape(Rectangle())
            .gesture(DragGesture()
                .onChanged {
                    let dragFactor = 200.0
                    if !isDragging {
                        isDragging = true
                        valueOffset = Utils.linearToExponential(
                            normalizedValue(value),
                            curve: curve
                        ) * dragFactor
                    }
                    var newValue = ($0.translation.height * -1) + valueOffset
                    newValue = max(0, min(1, newValue / dragFactor))
                    internalValue = newValue
                    value = Utils.exponentialToLinear(
                        newValue,
                        curve: curve
                    ) * (range.upperBound - range.lowerBound) + range.lowerBound
                }
                .onEnded { _ in
                    isDragging = false
                })
            .gesture(TapGesture(count: 2).onEnded { _ in
                value = defaultValue
            })
            
            // label
            Text(text).monospaced()
        }
        .padding(.bottom, 20)
    }
   
    private func normalizedValue(_ value: Double) -> Double {
        (value - range.lowerBound) / (range.upperBound - range.lowerBound)
    }
}
