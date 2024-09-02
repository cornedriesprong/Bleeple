//  ViewModel.swift
//  Bleeple
//
//  Created by Corné on 8/8/24.
//

import Combine
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

        var carrierFreq: Double = 440.0 {
            didSet {
                setParameter(index: 0, value: carrierFreq)
            }
        }

        var modFreq: Double = 660.0 {
            didSet {
                setParameter(index: 1, value: modFreq)
            }
        }

        var cutoff: Double = 5000.0 {
            didSet {
                setParameter(index: 2, value: cutoff)
            }
        }

        var resonance: Double = 0.717 {
            didSet {
                setParameter(index: 3, value: resonance)
            }
        }

        var fmAmount: Double = 0.5 {
            didSet {
                setParameter(index: 4, value: fmAmount)
            }
        }

        var modAmount: Double = 0.5 {
            didSet {
                setParameter(index: 5, value: modAmount)
            }
        }

        var isPlaying = true {
            didSet {
                engine.setIsPlaying(isPlaying)
                if !isPlaying {
                    activePitches.removeAll()
                }
            }
        }

        var selectedTrack = 1 {
            didSet {
                activePitches.removeAll()
            }
        }

        var playbackPosition = 0.0
        var activePitches = Set<Int8>()

        @ObservationIgnored var playingIndices: [Int] = []
        @ObservationIgnored private var heldEvents = Set<Event>()

        private let engine = AudioEngine()
        private var history = [Command]()
        private var position = -1
        private var cancellables = Set<AnyCancellable>()

        // MARK: - Initialization

        private init() {
            setupCallbacks()
        }

        // MARK: - Public methods

        func noteOn(_ pitch: Int) {
            let pitch = Int8(pitch)
            engine.noteOn(
                pitch: pitch,
                velocity: 100,
                track: Int8(selectedTrack),
                param1: 0.2,
                param2: 0.5
            )

            guard isPlaying else { return }
            let quantized = round(playbackPosition * 4)
            let event = Event(
                pitch: pitch,
                start: quantized,
                duration: .infinity,
                track: Int8(selectedTrack)
            )
            heldEvents.insert(event)
        }

        func noteOff(_ pitch: Int) {
            engine.noteOff(
                pitch: Int8(pitch),
                track: Int8(selectedTrack)
            )

            guard isPlaying else { return }
            let quantized = ceil(playbackPosition * 4)
            for var event in heldEvents where event.pitch == pitch {
                // set actual event duration, now that we have the note off time
                event.duration = max(1, quantized - event.start)
                push(.insert(event: event))
                heldEvents.remove(event)
            }
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

        func setParameter(_ parameter: Parameter, value: Double, curve: Double) {
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
                    track: event.track,
                    cutoff: Float(event.cutoff),
                    q: Float(event.q)
                )
            }
        }

        private func setParameter(index: Int, value: Double) {
            engine.setParameter(
                Int8(index),
                value: Float(value),
                track: Int8(selectedTrack)
            )
        }

        private func setupCallbacks() {
            set_playback_progress_callback { progress in
                DispatchQueue.main.async {
                    ViewModel.shared.playbackPosition = Double(progress)
                }
            }

            set_note_played_callback { noteOn, pitch, track in
                DispatchQueue.main.async {
                    guard track == ViewModel.shared.selectedTrack else { return }
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
