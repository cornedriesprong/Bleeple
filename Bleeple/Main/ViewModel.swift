//  ViewModel.swift
//  Bleeple
//
//  Created by Corné on 8/8/24.
//

import SwiftUI

extension MainView {
    @Observable final class ViewModel {
        // MARK: - Types
        
        static let shared = ViewModel()
        
        enum Parameter: Int {
            case cutoff
            case q
        }
        
        private enum Command {
            case insert(event: Event)
            case delete(event: Event)
            case transaction(commands: [Command])
        }
        
        // MARK: - Properties
        
        var events = [Event]() {
            didSet {
                updateEngine()
            }
        }
        
        var damping: Double = 0.5 {
            didSet {
                engine.setParameter(0, to: Float(damping))
            }
        }

        var tone: Double = 0.5 {
            didSet {
                engine.setParameter(1, to: Float(tone))
            }
        }

        var delay: Double = 0.5 {
            didSet {
                engine.setParameter(2, to: Float(delay))
            }
        }

        var reverb: Double = 0.5 {
            didSet {
                engine.setParameter(3, to: Float(reverb))
            }
        }

        var selectedSound: PlaitsEngine = .virtualAnalog1 {
            didSet {
                engine.setSound(Int8(selectedSound.rawValue))
            }
        }

        var playbackPosition: Double = 0.0
        var activePitches = Set<Int8>()

        @ObservationIgnored var playingIndices: [Int] = []
        @ObservationIgnored private var heldEvents = Set<Event>()

        private let engine = AudioEngine()
        private var history = [Command]()
        private var position = -1

        // MARK: - Initialization
           
        private init() {
            setupCallback()
        }
        
        // MARK: - Public methods
        
        func noteOn(_ pitch: Int) {
            let pitch = Int8(pitch)
            let quantized = round(playbackPosition * 4)
            let event = Event(pitch: pitch, start: quantized, duration: .infinity)
            heldEvents.insert(event)
        
            engine.noteOn(pitch: pitch, velocity: 100, param1: 0.2, param2: 0.5)
        }
        
        func noteOff(_ pitch: Int) {
            let quantized = ceil(playbackPosition * 4)
            for var event in heldEvents where event.pitch == pitch {
                // set actual event duration, now that we have the note off time
                event.duration = max(1, quantized - event.start)
                push(.insert(event: event))
                heldEvents.remove(event)
            }
            
            engine.noteOff(pitch: Int8(pitch))
        }

        func addEvent(_ event: Event) {
            push(.insert(event: event))
        }
        
        func removeEvent(_ event: Event) {
            push(.delete(event: event))
        }
        
        func deselectAll() {
            for index in events.indices {
                events[index].isSelected = false
            }
        }
        
        func undo() {
            if position >= 0 {
                let command = history[position]
                applyReversed(command)
                position -= 1
            }
        }
        
        func redo() {
            if position < history.count - 1 {
                position += 1
                let command = history[position]
                apply(command)
            }
        }
        
        func clear() {
            let selectedEvents = events.filter { $0.isSelected }
            let eventsToDelete = selectedEvents.isEmpty ? events : selectedEvents
            let commands: [Command] = eventsToDelete.map { .delete(event: $0) }
            push(.transaction(commands: commands))
           
            // clear engine here for now
            engine.clearEvents()
        }

        func setParameter(_ parameter: Parameter, value: Double) {
            for (index, event) in events.enumerated() where event.isSelected == true {
                switch parameter {
                case .cutoff:
                    events[index].cutoff = value
                case .q:
                    events[index].q = value
                }
            }
        }
        
        // MARK: - Private methods
        
        private func push(_ command: Command) {
            history.removeSubrange((position + 1)...)
            history.append(command)
            position += 1
            apply(command)
        }

        private func apply(_ command: Command) {
            switch command {
            case .insert(let event):
                events.append(event)

            case .delete(let event):
                events.removeAll { $0 == event }
                
            case .transaction(let commands):
                for command in commands {
                    apply(command)
                }
            }
        }
        
        private func applyReversed(_ command: Command) {
            switch command {
            case .insert(let event):
                events.removeAll { $0 == event }
                
            case .delete(let event):
                events.append(event)
                
            case .transaction(let commands):
                for command in commands.reversed() {
                    applyReversed(command)
                }
            }
        }

        private func updateEngine() {
            engine.clearEvents()
            for event in events {
                engine.addEvent(
                    step: Int(event.start),
                    pitch: event.pitch,
                    duration: Float(event.duration / 4.0),
                    cutoff: Float(event.cutoff),
                    q: Float(event.q)
                )
            }
        }
        
        private func setupCallback() {
            set_playback_progress_callback { progress in
                DispatchQueue.main.async {
                    ViewModel.shared.playbackPosition = Double(progress)
                }
            }
            
            set_note_played_callback { noteOn, pitch in
                DispatchQueue.main.async {
                    if noteOn {
                        ViewModel.shared.activePitches.insert(pitch)
                    } else {
                        ViewModel.shared.activePitches.remove(pitch)
                    }
                }
            }
        }
    }
}
