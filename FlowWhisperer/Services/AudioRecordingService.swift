import Foundation
import AVFoundation
import SwiftUI

class AudioRecordingService: NSObject, ObservableObject {
    private var audioRecorder: AVAudioRecorder?
    private var recordingURL: URL?
    
    @Published var isRecording = false
    @Published var hasPermission = true // macOS handles permissions differently
    
    override init() {
        super.init()
        // No audio session setup needed on macOS
    }
    
    func startRecording() -> Bool {
        print("🎤 AUDIO DEBUG: startRecording() called")
        print("🎤 AUDIO DEBUG: hasPermission: \(hasPermission), isRecording: \(isRecording)")
        
        guard hasPermission else {
            print("❌ AUDIO DEBUG: No microphone permission")
            return false
        }
        
        guard !isRecording else {
            print("⚠️ AUDIO DEBUG: Already recording")
            return false
        }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory,
                                                   in: .userDomainMask)[0]
        let audioFilename = documentsPath.appendingPathComponent("FlowWhisperer_\(Date().timeIntervalSince1970).m4a")
        
        print("🎤 AUDIO DEBUG: Documents path: \(documentsPath.path)")
        print("🎤 AUDIO DEBUG: Audio filename: \(audioFilename.path)")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        print("🎤 AUDIO DEBUG: Audio settings: \(settings)")
        
        do {
            print("🎤 AUDIO DEBUG: Creating AVAudioRecorder...")
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            
            print("🎤 AUDIO DEBUG: Starting recording...")
            let recordResult = audioRecorder?.record()
            print("🎤 AUDIO DEBUG: Record result: \(recordResult ?? false)")
            
            recordingURL = audioFilename
            isRecording = true
            
            print("✅ AUDIO DEBUG: Started recording to: \(audioFilename)")
            return true
        } catch {
            print("❌ AUDIO DEBUG: Failed to start recording: \(error)")
            print("❌ AUDIO DEBUG: Error details: \(error.localizedDescription)")
            return false
        }
    }
    
    func stopRecording() -> URL? {
        print("🛑 AUDIO DEBUG: stopRecording() called")
        print("🛑 AUDIO DEBUG: isRecording: \(isRecording)")
        
        guard isRecording else {
            print("⚠️ AUDIO DEBUG: Not currently recording")
            return nil
        }
        
        print("🛑 AUDIO DEBUG: Stopping audio recorder...")
        audioRecorder?.stop()
        isRecording = false
        
        let url = recordingURL
        recordingURL = nil
        
        print("✅ AUDIO DEBUG: Stopped recording. File saved at: \(url?.path ?? "unknown")")
        
        // Check if file exists and get size
        if let url = url {
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                let fileSize = attributes[.size] as? Int64 ?? 0
                print("📁 AUDIO DEBUG: File size: \(fileSize) bytes")
            } catch {
                print("❌ AUDIO DEBUG: Error getting file attributes: \(error)")
            }
        }
        
        return url
    }
    
    func cleanup() {
        // Clean up old recording files
        let documentsPath = FileManager.default.urls(for: .documentDirectory,
                                                   in: .userDomainMask)[0]
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: documentsPath,
                                                                  includingPropertiesForKeys: nil)
            
            for file in files {
                if file.lastPathComponent.hasPrefix("FlowWhisperer_") {
                    // Delete files older than 1 hour
                    let attributes = try FileManager.default.attributesOfItem(atPath: file.path)
                    if let creationDate = attributes[.creationDate] as? Date,
                       Date().timeIntervalSince(creationDate) > 3600 {
                        try FileManager.default.removeItem(at: file)
                        print("Cleaned up old recording: \(file.lastPathComponent)")
                    }
                }
            }
        } catch {
            print("Failed to cleanup old recordings: \(error)")
        }
    }
    
    func openSystemPreferences() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")!
        NSWorkspace.shared.open(url)
    }
}

extension AudioRecordingService: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            print("Recording failed")
            isRecording = false
            recordingURL = nil
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        print("Recording encode error: \(error?.localizedDescription ?? "Unknown error")")
        isRecording = false
        recordingURL = nil
    }
}