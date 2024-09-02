//
//  ColorTheme.swift
//  Bleeple
//
//  Created by Corné on 8/8/24.
//

import SwiftUI
import CP3Music

struct ColorTheme: EnvironmentKey {
    static let defaultValue: Color = .cp3Red
}

struct Scale: EnvironmentKey {
    static let defaultValue = CP3Music.Scale(CP3Music.Key(.c), .major)
}

extension EnvironmentValues {
    // TODO: use @Entry macro
    var color: Color {
        get { self[ColorTheme.self] }
        set { self[ColorTheme.self] = newValue }
    }
    
    var scale: CP3Music.Scale {
        get { self[Scale.self] }
        set { self[Scale.self] = newValue }
    }
}
