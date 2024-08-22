//
//  PlaitsVoice.swift
//  Bleeple
//
//  Created by Corné on 8/22/24.
//

import Foundation

enum PlaitsEngine: Int, CaseIterable {
    case virtualAnalog1
    case phaseDistortion
    case sixOp1
    case sixOp2
    case sixOp3
    case waveTerrain
    case stringMachine
    case chiptune
    case virtualAnalog2
    case waveShaping
    case fm
    case grain
    case additive
    case waveTable
    case chord
    case speech
    case swarm
    case noise
    case particle
    case string
    case modal
    case bassDrum
    case snareDrum
    case hihat
    
    var enabled: Bool {
        switch self {
        case .sixOp1, .sixOp2, .sixOp3:
            false
        default: true
        }
    }
}

extension PlaitsEngine: CustomStringConvertible {
    var description: String {
        switch self {
        case .virtualAnalog1:
            "virtual analog"
        case .phaseDistortion:
            "phase distortion"
        case .sixOp1:
            "six op fm"
        case .sixOp2:
            "six op fm"
        case .sixOp3:
            "six op fm"
        case .waveTerrain:
            "wave terrain"
        case .stringMachine:
            "string machine"
        case .chiptune:
            "chiptune"
        case .virtualAnalog2:
            "virtual analog"
        case .waveShaping:
            "waveshaping"
        case .fm:
            "fm"
        case .grain:
            "grain"
        case .additive:
            "additive"
        case .waveTable:
            "wavetable"
        case .chord:
            "chord"
        case .speech:
            "speech"
        case .swarm:
            "swarm"
        case .noise:
            "noise"
        case .particle:
            "particle"
        case .string:
            "string"
        case .modal:
            "modal"
        case .bassDrum:
            "bass drum"
        case .snareDrum:
            "snare drum"
        case .hihat:
            "hihat"
        }
    }
}
