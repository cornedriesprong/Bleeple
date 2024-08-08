//
//  CellView.swift
//  Bleeple
//
//  Created by Corné on 8/8/24.
//

import SwiftUI

struct CellView: View {
    @Binding var isActive: Bool
    
    var body: some View {
        Rectangle()
            .foregroundStyle(.red)
            .opacity(isActive ? 1 : 0.1)
            .onTapGesture {
                isActive.toggle()
            }
            .accessibilityLabel(isActive ? "Active cell" : "Inactive cell")
            .accessibilityHint("Tap to toggle")
    }
}
