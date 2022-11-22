//
//  ViewController.swift
//  EnglishNumbers
//
//  Created by Sezer on 15.11.2022.
//

import UIKit
import Speech
import AVKit

class ViewController: UIViewController, SFSpeechRecognizerDelegate {

    
    @IBOutlet weak var lblNext: UILabel!
    @IBOutlet weak var imgResult: UIImageView!
    @IBOutlet weak var lblNumber: UILabel!
    @IBOutlet weak var imgMic: UIImageView!
    
    let speechRecognizer        = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    var recognitionRequest      : SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask         : SFSpeechRecognitionTask?
    let audioEngine             = AVAudioEngine()
    
    var spokenNumber=""
    var isMicOpen = false
    var failTimes = 0
    var timer = Timer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupSpeech()
        imgResult.isHidden = true
        lblNext.isHidden = true
        
        generateRandomNumber()
        
        imgMic.isUserInteractionEnabled=true
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(btnMic_Clicked))
        imgMic.addGestureRecognizer(gestureRecognizer)
        
        lblNext.isUserInteractionEnabled=true
        let gestureRecognizerNext = UITapGestureRecognizer(target: self, action: #selector(lblNext_Clicked))
        lblNext.addGestureRecognizer(gestureRecognizerNext)
    }
    
    func generateRandomNumber(){
        lblNumber.text = String(Int.random(in: 10..<100))
    }
    @objc func lblNext_Clicked(){
        lblNext.isHidden = true
        imgResult.isHidden = true
        isMicOpen = false
        generateRandomNumber()
        failTimes = 0
    }
    
    @objc func btnMic_Clicked() {
            switch isMicOpen {
            case false:
                self.startRecording()
            case true:
                self.stopRecording()
            }
        }

    func startRecording() {
        isMicOpen = true
        imgMic.image = UIImage(named: "micOff")
        spokenNumber = ""
            // Clear all previous session data and cancel task
            if recognitionTask != nil {
                recognitionTask?.cancel()
                recognitionTask = nil
            }

            // Create instance of audio session to record voice
            let audioSession = AVAudioSession.sharedInstance()
            do {
                try audioSession.setCategory(AVAudioSession.Category.playAndRecord, mode: .spokenAudio, options: .defaultToSpeaker)
                try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            } catch {
                print("audioSession properties weren't set because of an error.")
            }

            self.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

            let inputNode = audioEngine.inputNode

            guard let recognitionRequest = recognitionRequest else {
                fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
            }

            recognitionRequest.shouldReportPartialResults = true

            self.recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in

                var isFinal = false

                if result != nil {

                    let resultText = result?.bestTranscription.formattedString
                    self.spokenNumber = resultText ?? ""
                    //print(resultText ?? "")
                    isFinal = (result?.isFinal)!
                }

                if error != nil || isFinal {

                    self.audioEngine.stop()
                    inputNode.removeTap(onBus: 0)

                    self.recognitionRequest = nil
                    self.recognitionTask = nil
                }
            })

            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
                self.recognitionRequest?.append(buffer)
            }

            self.audioEngine.prepare()

            do {
                try self.audioEngine.start()
            } catch {
                print("audioEngine couldn't start because of an error.")
            }
        }
    @objc func stopRecording(){
        isMicOpen = false
        imgMic.image = UIImage(named: "micOn")
        self.audioEngine.stop()
        self.recognitionRequest?.endAudio()
        print(self.spokenNumber)
        checkTruth()
    }
    
    func checkTruth(){
        if lblNumber.text == spokenNumber{
            imgResult.isHidden = false
            imgResult.image = UIImage(named: "Ok")
            failTimes = 0
            
            timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(changeResultImg), userInfo: nil, repeats: true)
        }else{
            imgResult.isHidden = false
            imgResult.image = UIImage(named: "error")
            failTimes+=1
            if failTimes > 2 {
                lblNext.isHidden = false
            }
        }
    }
    
    @objc func changeResultImg(){
        timer.invalidate()
        imgResult.isHidden = true
        generateRandomNumber()
    }
    
    func setupSpeech() {
            self.speechRecognizer?.delegate = self

            SFSpeechRecognizer.requestAuthorization { (authStatus) in
                switch authStatus {
                case .denied:
                    print("User denied access to speech recognition")
                case .restricted:
                    print("Speech recognition restricted on this device")
                case .notDetermined:
                    print("Speech recognition not yet authorized")
                case .authorized:
                    print("Authorized")
                @unknown default:
                    print("")
                }
              //  self.isMicOpen = isButtonEnabled
            }
        }




}

