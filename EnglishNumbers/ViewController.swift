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
    @IBOutlet weak var roundedLayer: UIView!
    @IBOutlet weak var lblResultDesc: UILabel!
    @IBOutlet weak var animationAreaLayer: UIView!
    
    let speechRecognizer        = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    var recognitionRequest      : SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask         : SFSpeechRecognitionTask?
    let audioEngine             = AVAudioEngine()
    
    
    var spokenNumber=""
    var isMicOpen = false
    var failTimes = 0
    var timer = Timer()
    var selectedRange = 100
    var isVibrationOpen = true
    var isSoundOpen = true
    var animationTimer: Timer?
    let animationTimeInterval: TimeInterval = 0.6
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupSpeech()
        checkMicPermission()

        checkDarkMode()
        roundedLayer.clipsToBounds = true
        roundedLayer.layer.cornerRadius = 65
        roundedLayer.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        animationAreaLayer.backgroundColor = UIColor(red: 0.922, green: 0.941, blue: 0.996, alpha: 1)
        
        imgResult.isHidden = true
        lblResultDesc.isHidden = true
        lblNext.isHidden = true
        
        imgMic.isUserInteractionEnabled=true
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(btnMic_Clicked))
        imgMic.addGestureRecognizer(gestureRecognizer)
        
        lblNext.isUserInteractionEnabled=true
        let gestureRecognizerNext = UITapGestureRecognizer(target: self, action: #selector(lblNext_Clicked))
        lblNext.addGestureRecognizer(gestureRecognizerNext)
    }
    
    func checkDarkMode(){
        if self.traitCollection.userInterfaceStyle == .dark {
            lblNumber.textColor = UIColor.black
            view.backgroundColor = UIColor.white
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .darkContent
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if let SelectedRange = UserDefaults.standard.string(forKey: "SelectedRange"){
            if SelectedRange == "0"{
                self.selectedRange = 10
            }else if SelectedRange == "1"{
                self.selectedRange = 100
            }else if SelectedRange == "2"{
                self.selectedRange = 1000
            }else{
                self.selectedRange = 100
            }
        }
        if let IsSoundOn = UserDefaults.standard.string(forKey: "IsSoundOn"){
            let _sound = NSString(string: IsSoundOn)
            isSoundOpen = _sound.boolValue
        }
        if let IsVibrationOn = UserDefaults.standard.string(forKey: "IsVibrationOn"){
            let _vibration = NSString(string: IsVibrationOn)
            isVibrationOpen = _vibration.boolValue
        }
        self.stopRecording()
        lblNext_Clicked()
    }
    
    func generateRandomNumber(num: Int){
        lblNumber.text = String(Int.random(in: 0..<num))
    }
    @objc func lblNext_Clicked(){
        lblNext.isHidden = true
        imgResult.isHidden = true
        lblResultDesc.isHidden = true
        isMicOpen = false
        generateRandomNumber(num: self.selectedRange)
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
    
    func beginAnimation() {
        timer = Timer.scheduledTimer(
            timeInterval: animationTimeInterval,
            target: self,
            selector: #selector(self.showCircles),
            userInfo: nil,
            repeats: true
        );
        animationTimer = timer
    }
    
    @objc func showCircles() {
        let v1 = UIView(frame: CGRect(x: 0, y: 0, width: imgMic.layer.bounds.height, height: imgMic.layer.bounds.height))
        v1.layer.borderColor = UIColor(red: 0.212, green: 0.416, blue: 0.949, alpha: 1).cgColor
        v1.layer.borderWidth = 1
        v1.layer.cornerRadius = v1.frame.width / 2
        v1.sendSubviewToBack(imgMic)
        v1.layer.position = CGPoint(
            x:(animationAreaLayer.bounds.width / 2) ,
            y:animationAreaLayer.bounds.height/2)

        animationAreaLayer.addSubview(v1)
        
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.toValue = CATransform3DMakeScale(1.3, 1.3, 1)
        animation.duration = 1
        animation.timingFunction = CAMediaTimingFunction.init(name: .easeOut)
        v1.layer.add(animation, forKey: "animation_scale")
    }

    func startRecording() {
        imgResult.isHidden = true
        lblResultDesc.isHidden = true
        beginAnimation()
        isMicOpen = true
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
        animationTimer?.invalidate()
        isMicOpen = false
        self.audioEngine.stop()
        self.recognitionRequest?.endAudio()
        print(self.spokenNumber)
        checkTruth()
    }
    
    func checkTruth(){
        if lblNumber.text == spokenNumber{
            self.successful()
        }else{
            let secondControl = secondCheck(num: spokenNumber)
            if secondControl == true{
                self.successful()
                return
            }
            
            imgResult.isHidden = false
            lblResultDesc.isHidden = false
            lblResultDesc.textColor = UIColor(red: 1, green: 0.337, blue: 0.337, alpha: 1)
            lblResultDesc.text = "False, try again"
            imgResult.image = UIImage(named: "error")
            failTimes+=1
            
            sendVibration()
       
            if failTimes > 2 {
                lblNext.isHidden = false
            }
        }
    }
    
    func successful(){
        imgResult.isHidden = false
        lblResultDesc.isHidden = false
        lblResultDesc.textColor = UIColor(red: 0, green: 0.737, blue: 0.424, alpha: 1)
        lblResultDesc.text = "True"
        imgResult.image = UIImage(named: "success")
        failTimes = 0
        
        playSound(sound: "success", type: "m4a")
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(changeResultImg), userInfo: nil, repeats: true)
    }
    
    func secondCheck(num: String)-> Bool {
        if (num == "Zero" && lblNumber.text == "0"){
            return true
        }else if (num == "One" && lblNumber.text == "1"){
            return true
        }else if (num == "Two" && lblNumber.text == "2"){
            return true
        }else if (num == "Three" && lblNumber.text == "3"){
            return true
        }else if (num == "Four" && lblNumber.text == "4"){
            return true
        }else if (num == "Five" && lblNumber.text == "5"){
            return true
        }else if (num == "Six" && lblNumber.text == "6"){
            return true
        }else if (num == "Seven" && lblNumber.text == "7"){
            return true
        }else if (num == "Eight" && lblNumber.text == "8"){
            return true
        }else if (num == "Nine" && lblNumber.text == "9"){
            return true
        }else if (num == "Ten" && lblNumber.text == "10"){
            return true
        }else{
            return false
        }
    }
    
    func sendVibration(){
        if isVibrationOpen{
            let tapticFeedback = UINotificationFeedbackGenerator()
            tapticFeedback.notificationOccurred(.warning)
        }
    }
    
    @objc func changeResultImg(){
        timer.invalidate()
        imgResult.isHidden = true
        lblResultDesc.isHidden = true
        generateRandomNumber(num: self.selectedRange)
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
    
    var audioPlayer: AVAudioPlayer?
    func playSound(sound: String, type: String) {
        if isSoundOpen{
            if let path = Bundle.main.path(forResource: sound, ofType: type) {
                do {
                    try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
                    try AVAudioSession.sharedInstance().setActive(true)

                    audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
                    audioPlayer?.play()
                } catch {
                    print("ERROR")
                }
            }
        }
    }
    
    func checkMicPermission() {
        let isGranted = AVAudioSession.sharedInstance().recordPermission
        if(isGranted == .denied || isGranted == .undetermined){
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                /*if granted {
                    print("yes")
                } else {
                    print("no")
                }*/
            }
        }
    }
}

