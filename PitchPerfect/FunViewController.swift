//
//  FunViewController.swift
//  PitchPerfect
//
//  Created by Rohit Pal on 20/11/17.
//  Copyright © 2017 Technobells. All rights reserved.
//

import UIKit
import AVFoundation

class FunViewController: UIViewController {

    enum ButtonType: Int {
        case echo = 0, reverb, fast, slow, lowPitch, highPitch
    }

    enum ScreenState {
        case playingAudio, notPlayingAudio
    }

    struct Alerts {
        static let DismissAlert = "Dismiss"
        static let RecordingDisabledTitle = "Recording Disabled"
        static let RecordingDisabledMessage = "You've disabled this app from recording your microphone. Check Settings."
        static let RecordingFailedTitle = "Recording Failed"
        static let RecordingFailedMessage = "Something went wrong with your recording."
        static let AudioRecorderError = "Audio Recorder Error"
        static let AudioSessionError = "Audio Session Error"
        static let AudioRecordingError = "Audio Recording Error"
        static let AudioFileError = "Audio File Error"
        static let AudioEngineError = "Audio Engine Error"
    }

    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var echoButton: UIButton!
    @IBOutlet weak var reverbButton: UIButton!
    @IBOutlet weak var fastButton: UIButton!
    @IBOutlet weak var slowButton: UIButton!
    @IBOutlet weak var lowPitchButton: UIButton!
    @IBOutlet weak var highPitchButton: UIButton!

    var audioUrl: URL!
    var audioEngine: AVAudioEngine!
    var audioFile: AVAudioFile!
    var audioPlayerNode: AVAudioPlayerNode!
    var stopTimer: Timer!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupAudio()
        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(_ animated: Bool) {
        configureUI(state: .notPlayingAudio)
    }

    // MARK: Audio Functions
    func setupAudio() {
        // initialize (recording) audio file
        do {
            audioFile = try AVAudioFile(forReading: audioUrl as URL)
        } catch {
            showAlert(Alerts.AudioFileError, message: String(describing: error))
        }
    }

    func playSound(rate: Float? = nil, pitch: Float? = nil, echo: Bool = false, reverb: Bool = false) {

        // initialize audio engine components
        audioEngine = AVAudioEngine()

        // node for playing audio
        audioPlayerNode = AVAudioPlayerNode()
        audioEngine.attach(audioPlayerNode)

        // node for adjusting rate/pitch
        let changeRatePitchNode = AVAudioUnitTimePitch()
        if let pitch = pitch {
            changeRatePitchNode.pitch = pitch
        }
        if let rate = rate {
            changeRatePitchNode.rate = rate
        }
        audioEngine.attach(changeRatePitchNode)

        // node for echo
        let echoNode = AVAudioUnitDistortion()
        echoNode.loadFactoryPreset(.multiEcho1)
        audioEngine.attach(echoNode)

        // node for reverb
        let reverbNode = AVAudioUnitReverb()
        reverbNode.loadFactoryPreset(.largeHall)
        reverbNode.wetDryMix = 50
        audioEngine.attach(reverbNode)

        // connect nodes
        if echo == true && reverb == true {
            connectAudioNodes(audioPlayerNode, changeRatePitchNode, echoNode, reverbNode, audioEngine.outputNode)
        } else if echo == true {
            connectAudioNodes(audioPlayerNode, changeRatePitchNode, echoNode, audioEngine.outputNode)
        } else if reverb == true {
            connectAudioNodes(audioPlayerNode, changeRatePitchNode, reverbNode, audioEngine.outputNode)
        } else {
            connectAudioNodes(audioPlayerNode, changeRatePitchNode, audioEngine.outputNode)
        }

        // schedule to play and start the engine!
        audioPlayerNode.stop()
        audioPlayerNode.scheduleFile(audioFile, at: nil) {

            var delayInSeconds: Double = 0

            if let lastRenderTime = self.audioPlayerNode.lastRenderTime, let playerTime = self.audioPlayerNode.playerTime(forNodeTime: lastRenderTime) {

                if let rate = rate {
                    delayInSeconds = Double(self.audioFile.length - playerTime.sampleTime) / Double(self.audioFile.processingFormat.sampleRate) / Double(rate)
                } else {
                    delayInSeconds = Double(self.audioFile.length - playerTime.sampleTime) / Double(self.audioFile.processingFormat.sampleRate)
                }
            }

            // schedule a stop timer for when audio finishes playing
            self.stopTimer = Timer(timeInterval: delayInSeconds, target: self, selector: #selector(self.stopAudio), userInfo: nil, repeats: false)
            RunLoop.main.add(self.stopTimer!, forMode: RunLoopMode.defaultRunLoopMode)
        }

        do {
            try audioEngine.start()
        } catch {
            showAlert(Alerts.AudioEngineError, message: String(describing: error))
            return
        }

        // play the recording!
        audioPlayerNode.play()
    }

    @objc func stopAudio() {

        if let audioPlayerNode = audioPlayerNode {
            audioPlayerNode.stop()
        }

        if let stopTimer = stopTimer {
            stopTimer.invalidate()
        }

        configureUI(state: .notPlayingAudio)

        if let audioEngine = audioEngine {
            audioEngine.stop()
            audioEngine.reset()
        }
    }

    // MARK: Connect List of Audio Nodes

    func connectAudioNodes(_ nodes: AVAudioNode...) {
        for x in 0..<nodes.count-1 {
            audioEngine.connect(nodes[x], to: nodes[x+1], format: audioFile.processingFormat)
        }
    }

    func configureUI(state: ScreenState) {
        stopButton.isEnabled = state == .playingAudio
        echoButton.isEnabled = state == .notPlayingAudio
        echoButton.isEnabled = state == .notPlayingAudio
        reverbButton.isEnabled = state == .notPlayingAudio
        fastButton.isEnabled = state == .notPlayingAudio
        slowButton.isEnabled = state == .notPlayingAudio
        lowPitchButton.isEnabled = state == .notPlayingAudio
        highPitchButton.isEnabled = state == .notPlayingAudio
    }

    @IBAction func playSoundWithEffect(_ sender: UIButton) {
        if let buttonType = ButtonType(rawValue: sender.tag) {
            switch buttonType {
            case .slow:
                playSound(rate: 0.5)
            case .fast:
                playSound(rate: 1.5)
            case .highPitch:
                playSound(pitch: 1200)
            case .lowPitch:
                playSound(pitch: -1200)
            case .echo:
                playSound(echo: true)
            case .reverb:
                playSound(reverb: true)
            }
            configureUI(state: .playingAudio)
        }
    }

    @IBAction func stopSound(_ sender: UIButton) {
        if let audioPlayerNode = audioPlayerNode {
            audioPlayerNode.stop()
        }
        if let stopTimer = stopTimer {
            stopTimer.invalidate()
        }
        if let audioEngine = audioEngine {
            audioEngine.stop()
            audioEngine.reset()
        }
        configureUI(state: .notPlayingAudio)
    }

    func showAlert(_ title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Alerts.DismissAlert, style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

}
