//
//  MainViewModel.swift
//  Bleeple
//
//  Created by Corné on 8/8/24.
//

import SwiftUI

extension MainView {
    @Observable final class ViewModel {
        var grid = Array(repeating: Array(repeating: false, count: 16), count: 8)
        var damping: Double = 0.5
        var tone: Double = 0.5
        var delay: Double = 0.5
        var reverb: Double = 0.5
        
        func clear() {
            for (x, row) in grid.enumerated() {
                for (y, isOn) in row.enumerated() where isOn {
                    grid[x][y] = false
                }
            }
        }
    }
}
