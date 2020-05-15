//
//  ViewController.swift
//  Decibles
//
//  Created by Khan on 4/18/20.
//  Copyright © 2020 Windchillmedia. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    var dataPoints = [DataPoint]()
    
    struct DataPoint {
        var timestamp: Date
        var average: Float
        var peak: Float
    }

    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        startButton.layer.cornerRadius = 10
        stopButton.layer.cornerRadius = 10
    }
    
    var timer: DispatchSourceTimer?
    var startDate = Date()
    
    @IBAction func startRecording() {
        let recordSettings = [
            AVSampleRateKey : NSNumber(value: Float(44100.0) as Float),
            AVFormatIDKey : NSNumber(value: Int32(kAudioFormatMPEG4AAC) as Int32),
            AVNumberOfChannelsKey : NSNumber(value: 1 as Int32),
            AVEncoderAudioQualityKey : NSNumber(value: Int32(AVAudioQuality.max.rawValue) as Int32),
        ]

        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(AVAudioSession.Category.playAndRecord)
            let audioRecorder = try AVAudioRecorder(url: directoryURL()!, settings: recordSettings)
            audioRecorder.prepareToRecord()
            audioRecorder.record()
            try audioSession.setActive(true)
            audioRecorder.isMeteringEnabled = true
            recordForever(audioRecorder: audioRecorder)
        } catch let err {
            print("Unable start recording", err)
        }
        
        startDate = Date()
    }
    
    func directoryURL() -> URL? {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = urls[0] as URL
        let soundURL = documentDirectory.appendingPathComponent("sound.m4a")
        return soundURL
    }
    
    func recordForever(audioRecorder: AVAudioRecorder) {
        let queue = DispatchQueue(label: "io.segment.decibel", attributes: .concurrent)
        timer = DispatchSource.makeTimerSource(flags: [], queue: queue)
        timer?.schedule(deadline: .now(), repeating: .seconds(1), leeway: .milliseconds(100))
        timer?.setEventHandler { [weak self] in
            audioRecorder.updateMeters()

             // NOTE: seems to be the approx correction to get real decibels
            let correction: Float = 100
            let average = audioRecorder.averagePower(forChannel: 0) + correction
            let peak = audioRecorder.peakPower(forChannel: 0) + correction
            self?.recordDatapoint(average: average, peak: peak)
        }
        timer?.resume()
    }

    func recordDatapoint(average: Float, peak: Float) {
        dataPoints.append(DataPoint(timestamp: Date(), average: average, peak: peak))
    }
    
    @IBAction func stopRecording() {
        timer?.cancel()
        timer = nil
        
        if dataPoints.count > 1 {
            let alert = UIAlertController(title: "File Name", message: "", preferredStyle: .alert)
            let action = UIAlertAction(title: "Name Input", style: .default) { (alertAction) in
                let field = alert.textFields![0] as UITextField
                var string = "Timestamp, Average, Peak\n"
                self.dataPoints.removeFirst()
                for point in self.dataPoints {
                    string.append(contentsOf: "\(String(describing: point.timestamp.timeIntervalSince1970 - self.startDate.timeIntervalSince1970)), \(String(describing: point.average)), \(String(describing: point.peak))\n")
                }
                do {
                    let fileURL = self.getDocumentsDirectory().appendingPathComponent("\(field.text ?? UUID().uuidString).csv")
                    try string.write(to: fileURL, atomically: true, encoding: .utf8)
                } catch {
                    print("error creating file, \(error.localizedDescription)")
                }
            }
            alert.addTextField { (textField) in
                textField.placeholder = "Enter filename"
            }
            alert.addAction(action)
            present(alert, animated: true, completion: nil)
        }
    }
    
    func getDocumentsDirectory() -> URL {
        // find all possible documents directories for this user
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}

