//
//  TopButton.swift
//  Bleeple
//
//  Created by Corné on 8/8/24.
//

import SwiftUI

struct TopButton: View {
    let imageName: String
    let handler: () -> Void

    var body: some View {
        Button(
            action: handler,
            label: {
                Image(systemName: imageName)
            })
    }
}
