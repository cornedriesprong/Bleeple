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
        
        var damping: Double = 0.5 {
            didSet {
                dampingSubject.send(Float(damping))
            }
        }
        @ObservationIgnored private let dampingSubject = PassthroughSubject<Float, Never>()

        var tone: Double = 0.5 {
            didSet {
                toneSubject.send(Float(tone))
            }
        }
        @ObservationIgnored private let toneSubject = PassthroughSubject<Float, Never>()

        var delay: Double = 0.5 {
            didSet {
                delaySubject.send(Float(delay))
            }
        }
        @ObservationIgnored private let delaySubject = PassthroughSubject<Float, Never>()

        var reverb: Double = 0.5 {
            didSet {
                reverbSubject.send(Float(reverb))
            }
        }
        @ObservationIgnored private let reverbSubject = PassthroughSubject<Float, Never>()

        var selectedSound: PlaitsEngine = .virtualAnalog1 {
            didSet {
                engine.setSound(
                    Int8(selectedSound.rawValue),
                    track: Int8(
                        selectedTrack
                    )
                )
            }
        }

        var isPlaying = true {
            didSet {
                engine.setIsPlaying(isPlaying)
            }
        }
        var selectedTrack = 1
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
            setupParameterPublishers()
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
                    track: event.track,
                    cutoff: Float(event.cutoff),
                    q: Float(event.q)
                )
            }
        }
        
        private func setupParameterPublishers() {
            dampingSubject
                .throttle(for: .seconds(0.2), scheduler: DispatchQueue.main, latest: true)
                .sink { [weak self] value in
                    guard let self else { return }
                    engine.setParameter(
                        0,
                        value: Float(value),
                        track: Int8(selectedTrack)
                    )
                }
                .store(in: &cancellables)
            
            toneSubject
                .throttle(for: .seconds(0.2), scheduler: DispatchQueue.main, latest: true)
                .sink { [weak self] value in
                    guard let self else { return }
                    engine.setParameter(
                        1,
                        value: Float(value),
                        track: Int8(selectedTrack)
                    )
                }
                .store(in: &cancellables)
            
            delaySubject
                .throttle(for: .seconds(0.2), scheduler: DispatchQueue.main, latest: true)
                .sink { [weak self] value in
                    guard let self else { return }
                    engine.setParameter(
                        2,
                        value: Float(value),
                        track: Int8(selectedTrack)
                    )
                }
                .store(in: &cancellables)
            
            reverbSubject
                .throttle(for: .seconds(0.2), scheduler: DispatchQueue.main, latest: true)
                .sink { [weak self] value in
                    guard let self else { return }
                    engine.setParameter(
                        3,
                        value: Float(value),
                        track: Int8(selectedTrack)
                    )
                }
                .store(in: &cancellables)
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
