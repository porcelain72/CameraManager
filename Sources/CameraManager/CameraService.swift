import AVFoundation
import Photos
import UIKit

public final class CameraService: NSObject, ObservableObject {
    private let session = AVCaptureSession()
    private var videoOutput = AVCaptureMovieFileOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var currentDevice: AVCaptureDevice?
   public private(set) var videoFileURL: URL?


    @Published public var isRecording = false
    public var settings: VideoSettings

    public init(settings: VideoSettings) {
        self.settings = settings
        super.init()
        configureSession()
    }

    public func getPreviewLayer() -> AVCaptureVideoPreviewLayer? {
        if previewLayer == nil {
            previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer?.videoGravity = .resizeAspectFill
        }
        return previewLayer
    }

    private func configureSession() {
        print("📸 Configuring session for position: \(settings.position)")

        session.beginConfiguration()
        session.sessionPreset = settings.avPreset

        // Remove old inputs
        session.inputs.forEach { session.removeInput($0) }
        session.outputs.forEach { session.removeOutput($0) }

        // Add camera input
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: settings.position),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input)
        else {
            print("❌ Unable to access camera.")
            session.commitConfiguration()
            return
        }

        currentDevice = device
        session.addInput(input)

        // Add microphone
        if let mic = AVCaptureDevice.default(for: .audio),
           let micInput = try? AVCaptureDeviceInput(device: mic),
           session.canAddInput(micInput) {
            session.addInput(micInput)
        }

        
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
            if let connection = videoOutput.connection(with: .video) {
                if connection.isVideoOrientationSupported {
                    connection.videoOrientation = .portrait
                } else {
                    print("⚠️ Orientation not supported")
                }
            } else {
                print("❌ No video connection found")
            }
            print("✅ Added videoOutput\(videoOutput.description)")
        } else {
            print("❌ Couldn't add videoOutput")
        }


        session.commitConfiguration()
    }

    public func startSession() {
        guard !session.isRunning else {
            print("⚠️ Session already running")
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
            print("✅ Session started")
        }
    }


    public func stopSession() {
        if session.isRunning {
            session.stopRunning()
        }
    }

    public func startRecording() {
        guard !isRecording else {
            print("⚠️ Already recording")
            return
        }

        let tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
        let fileName = UUID().uuidString + ".mov"
        let fileURL = tempDirectory.appendingPathComponent(fileName)

        print("▶️ Attempting to record to \(fileURL)")

        if let connection = videoOutput.connection(with: .video),
           connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
            print("🔄 Set video orientation to portrait")
        }

        if videoOutput.isRecording {
            print("⚠️ Output already recording — should not happen")
        }
        print(" videoOutput\(videoOutput.description)")

        videoOutput.startRecording(to: fileURL, recordingDelegate: self)
        isRecording = true
        print(" videoOutput\(videoOutput.description)")
    }


    public func stopRecording() {

        guard isRecording else {
            print("⚠️ Tried to stop but not recording")
            return
        }

        print("⏹ Calling stopRecording()")
        videoOutput.stopRecording()
        print(" videoOutput\(videoOutput.description)")
        isRecording = false
    }



    private func saveVideoToPhotos(url: URL) {
        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        } completionHandler: { success, error in
            if let error = error {
                print("❌ Error saving to Photos: \(error.localizedDescription)")
            } else {
                print("✅ Video saved to Photos.")
            }
        }
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate
extension CameraService: AVCaptureFileOutputRecordingDelegate {
    
    public func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        
        print("Strted recording")
    }
    public func fileOutput(_ output: AVCaptureFileOutput,
                           didFinishRecordingTo outputFileURL: URL,
                           from connections: [AVCaptureConnection],
                           error: Error?) {
        print("📹 Delegate method called")
        isRecording = false

        if let error = error {
            print("❌ Error during recording: \(error.localizedDescription)")
            return
        }

        print("✅ Recording saved to temp file: \(outputFileURL)")
        videoFileURL = outputFileURL
        saveVideoToPhotos(url: outputFileURL)
    }

}

