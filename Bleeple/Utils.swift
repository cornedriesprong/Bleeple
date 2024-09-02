//
//  Utils.swift
//  Bleeple
//
//  Created by Corné on 9/2/24.
//

import Foundation

enum Utils {
    static func linearToExponential(_ x: Double, curve: Int) -> Double {
        return pow(x, 1.0 / Double(curve))
    }
    
    static func exponentialToLinear(_ x: Double, curve: Int) -> Double {
        return pow(x, Double(curve))
    }
}
