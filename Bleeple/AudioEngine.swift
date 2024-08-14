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
    
    private let engine: OpaquePointer
    var audioEngine = AVAudioEngine()
    var sourceNode: AVAudioSourceNode?
    var format: AVAudioFormat
    
    // MARK: - Initialization

    init() {
        engine = engine_init()
        format = audioEngine.outputNode.outputFormat(forBus: 0)

        setupAudioEngine()
    }
    

    deinit {
        engine_free(engine)
    }
    
    // MARK: - Public methods
    
    func addEvent(step: Int, pitch: Int) {
        let beatTime: Float = Float(step) / 4.0
        let pitch: Int8 = Int8(pitch)
        let velocity: Int8 = 100
        let duration: Float = 0.5
        let parameter1: Float = 0.5
        let parameter2: Float = 0.2

        add_event(
            beatTime,
            pitch,
            velocity,
            duration,
            parameter1,
            parameter2
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
            let sampleTime = Int32(timeStamp.pointee.mSampleTime)

            var l = [Float](repeating: 0.0, count: Int(frameCount))
            var r = [Float](repeating: 0.0, count: Int(frameCount))

            render(
                engine,
                &l,
                &r,
                sampleTime,
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
}
