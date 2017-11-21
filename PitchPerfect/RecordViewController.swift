//
//  RecordViewController.swift
//  PitchPerfect
//
//  Created by Rohit Pal on 20/11/17.
//  Copyright © 2017 Technobells. All rights reserved.
//

import UIKit
import AVFoundation

class RecordViewController: UIViewController {
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var stopButton: UIButton!

    var audioRecorder: AVAudioRecorder!

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if audioRecorder != nil && audioRecorder.isRecording {
            recordButton.isEnabled = false
            stopButton.isHidden = false
            infoLabel.text = NSLocalizedString("Recording your voice", comment: "")
        } else {
            recordButton.isEnabled = true
            stopButton.isHidden = true
            infoLabel.text = NSLocalizedString("Tap to record your voice", comment: "")
        }
    }

    func askMicrophoneAccessPermission(completion: @escaping (_ success: Bool)-> Void) {
        switch AVAudioSession.sharedInstance().recordPermission() {
        case AVAudioSessionRecordPermission.granted:
            completion(true)
        case AVAudioSessionRecordPermission.denied:
            completion(false)
        case AVAudioSessionRecordPermission.undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                completion(granted)
            }
        }
    }

    func hasMicrophonePermission() -> Bool {
        return AVAudioSession.sharedInstance().recordPermission() == .granted
    }

    func recordVoice() {
        recordButton.isEnabled = false
        stopButton.isHidden = false
        let dirPath = NSSearchPathForDirectoriesInDomains(.documentDirectory,.userDomainMask, true)[0] as String
        let recordingName = "recordedVoice.wav"
        let pathArray = [dirPath, recordingName]
        let filePath = URL(string: pathArray.joined(separator: "/"))

        let session = AVAudioSession.sharedInstance()
        try! session.setCategory(AVAudioSessionCategoryPlayAndRecord, with:AVAudioSessionCategoryOptions.defaultToSpeaker)

        try! audioRecorder = AVAudioRecorder(url: filePath!, settings: [:])
        audioRecorder.delegate = self
        audioRecorder.isMeteringEnabled = true
        audioRecorder.prepareToRecord()
        audioRecorder.record()
        infoLabel.text = NSLocalizedString("Recording your voice", comment: "")
    }


    @IBAction func startRecording(_ sender: UIButton) {
        if hasMicrophonePermission() {
            recordVoice()
        } else {
            askMicrophoneAccessPermission {[weak self] granted in
                if granted {
                    self?.recordVoice()
                }
            }
        }
    }

    @IBAction func stopRecording(_ sender: UIButton) {
        audioRecorder.stop()
        try! AVAudioSession.sharedInstance().setActive(false)
        recordButton.isEnabled = true
        stopButton.isHidden = true
        infoLabel.text = NSLocalizedString("Tap to record your voice", comment: "")
    }
}

extension RecordViewController: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            let board = UIStoryboard(name: "Main", bundle: nil)
            if let funVc = board.instantiateViewController(withIdentifier: "FunViewController") as? FunViewController {
                funVc.audioUrl = recorder.url
                self.navigationController?.pushViewController(funVc, animated: true)
            }
        } else {
            print("Failed to record audio")
        }
    }
}
