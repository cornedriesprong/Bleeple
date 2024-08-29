//
//  AudioEngine.swift
//  Bleeple
//
//  Created by Corné on 7/24/24.
//

import AVFoundation
import Foundation

final class AudioEngine {
    // MARK: - Properties

    private var engine: OpaquePointer
    private var audioEngine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode?
    private var format: AVAudioFormat
    private var sampleRate = AVAudioSession.sharedInstance().sampleRate

    // MARK: - Initialization

    init() {
        engine = engine_init(Float(sampleRate))
        format = audioEngine.outputNode.outputFormat(forBus: 0)

        configureAudioSession()
        setupAudioEngine()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
    }

    deinit {
        engine_free(engine)
    }

    // MARK: - Public methods

    func setIsPlaying(_ isPlaying: Bool) {
        set_play_pause(engine, isPlaying)
    }

    func noteOn(pitch: Int8, velocity: Int8, track: Int8, param1: Float, param2: Float) {
        note_on(engine, pitch, velocity, track, param1, param2)
    }

    func noteOff(pitch: Int8, track: Int8) {
        note_off(engine, pitch, track)
    }

    func setSound(_ sound: Int8, track: Int8) {
        set_sound(engine, sound, track)
    }

    func setParameter(_ parameter: Int8, value: Float, track: Int8) {
        set_parameter(parameter, value, track)
    }

    func addEvent(step: Int, pitch: Int8, duration: Float, track: Int8, cutoff: Float, q: Float) {
        let beatTime = Float(step) / 4.0
        let pitch = Int8(pitch)
        let velocity: Int8 = 100

        add_event(
            beatTime,
            pitch,
            velocity,
            duration,
            track,
            cutoff,
            q
        )
    }

    func clearEvents() {
        clear_events()
    }

    // MARK: - Private methods

    private func setupAudioEngine() {
        let renderBlock: AVAudioSourceNodeRenderBlock = { [weak self] _, timeStamp, frameCount, audioBufferList in
            guard let self else { return noErr }
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)

            let tempo = 120.0
            let sampleTime = timeStamp.pointee.mSampleTime

            var l = [Float](repeating: 0.0, count: Int(frameCount))
            var r = [Float](repeating: 0.0, count: Int(frameCount))

            render(
                engine,
                &l,
                &r,
                Int64(sampleTime),
                Float(tempo),
                Int32(frameCount)
            )

            for frame in 0..<Int(frameCount) {
                for channel in 0..<ablPointer.count {
                    let data = ablPointer[channel].mData?.assumingMemoryBound(to: Float.self)
                    data?[frame] = channel == 0 ? l[frame] : r[frame]
                }
            }

            return noErr
        }

        sourceNode = AVAudioSourceNode(format: format, renderBlock: renderBlock)
        guard let sourceNode = sourceNode else { return }

        audioEngine.attach(sourceNode)
        audioEngine.connect(sourceNode, to: audioEngine.mainMixerNode, format: format)

        do {
            try audioEngine.start()
        } catch {
            print("Error starting the audio engine: \(error)")
        }
    }

    private func configureAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
        } catch {
            print("Failed to set audio session category and activate it: \(error)")
        }
    }

    @objc private func handleRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }

        if reason == .categoryChange || reason == .newDeviceAvailable || reason == .oldDeviceUnavailable {
            // reinitialize engine if audio route changed (sample rate might have changed)
            self.engine = engine_init(Float(sampleRate))
        }
    }
}
