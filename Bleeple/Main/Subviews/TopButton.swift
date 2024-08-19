//
//  TopButton.swift
//  Bleeple
//
//  Created by Corné on 8/8/24.
//

import SwiftUI

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
