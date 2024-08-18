//
//  ViewModel.swift
//  Bleeple
//
//  Created by Corné on 8/8/24.
//

import SwiftUI

extension MainView {
    @Observable final class ViewModel {
        // MARK: - Types
        
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
        
        var damping: Double = 0.5
        var tone: Double = 0.5
        var delay: Double = 0.5
        var reverb: Double = 0.5
        
        private let engine = AudioEngine()
        private var history = [Command]()
        private var position = -1

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
    }
}
