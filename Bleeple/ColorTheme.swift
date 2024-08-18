//
//  ColorTheme.swift
//  Bleeple
//
//  Created by Corné on 8/8/24.
//

import SwiftUI

struct ColorTheme: EnvironmentKey {
    static let defaultValue: Color = .red
}

extension EnvironmentValues {
    var color: Color {
        get { self[ColorTheme.self] }
        set { self[ColorTheme.self] = newValue }
    }
}

struct ShiftPressed: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var isShiftPressed: Bool {
        get { self[ShiftPressed.self] }
        set { self[ShiftPressed.self] = newValue }
    }
}
