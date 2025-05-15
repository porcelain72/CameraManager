import AVFoundation
import Photos

public final class CameraService: NSObject, ObservableObject {
    private(set) var session: AVCaptureSession?
    private var videoOutput: AVCaptureMovieFileOutput?
    private var previewLayer: AVCaptureVideoPreviewLayer?

    @Published public private(set) var isRecording = false
    public private(set) var videoFileURL: URL?
    private var currentSettings: VideoSettings

    public init(settings: VideoSettings) {
        self.currentSettings = settings
        super.init()
        configureSession(with: settings)
    }

    public func getPreviewLayer() -> AVCaptureVideoPreviewLayer? {
        return previewLayer
    }

    public func startSession() {
        guard let session = session, !session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
            print("✅ Camera session started")
        }
    }

    public func stopSession() {
        guard let session = session, session.isRunning else { return }
        session.stopRunning()
        print("⏹ Camera session stopped")
    }

    public func startRecording() {
        guard let videoOutput = videoOutput, !isRecording else { return }

        guard
                let directoryPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            else {
                print("Cannot access local file domain")
                return
            }
        
      //  let fileURL = FileManager.default.temporaryDirectory
        let fileURL = directoryPath
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")

        if let connection = videoOutput.connection(with: .video),
           connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }

        videoOutput.startRecording(to: fileURL, recordingDelegate: self)
        isRecording = true
        print("▶️ Recording started to \(fileURL)")
    }

    public func stopRecording() {
        guard isRecording, let videoOutput = videoOutput else { return }
        videoOutput.stopRecording()
        print("⏹ Stopping recording")
    }

    public func reloadSession(with settings: VideoSettings) {
        print("🔄 Reloading session with new settings")
        stopSession()
        configureSession(with: settings)
        startSession()
    }

    private func configureSession(with settings: VideoSettings) {
        currentSettings = settings
        session = AVCaptureSession()
        videoOutput = AVCaptureMovieFileOutput()

        guard let session = session, let videoOutput = videoOutput else { return }

        session.beginConfiguration()
        session.sessionPreset = settings.avPreset

        // Inputs
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: settings.position),
              let videoInput = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(videoInput)
        else {
            print("❌ Could not add video input")
            session.commitConfiguration()
            return
        }
        session.addInput(videoInput)

        if let mic = AVCaptureDevice.default(for: .audio),
           let micInput = try? AVCaptureDeviceInput(device: mic),
           session.canAddInput(micInput) {
            session.addInput(micInput)
        }

        // Output
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        } else {
            print("❌ Could not add video output")
        }

        session.commitConfiguration()

        // Preview
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer?.videoGravity = .resizeAspectFill
    }

    private func saveVideoToPhotos(url: URL) {
        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        } completionHandler: { success, error in
            if let error = error {
                print("❌ Save failed: \(error.localizedDescription)")
            } else {
                print("📸 Video saved to Photos")
            }
        }
    }
}

// MARK: - Delegate

extension CameraService: AVCaptureFileOutputRecordingDelegate {
    public func fileOutput(_ output: AVCaptureFileOutput,
                           didFinishRecordingTo outputFileURL: URL,
                           from connections: [AVCaptureConnection],
                           error: Error?) {
        isRecording = false

        if let error = error {
            print("❌ Recording error: \(error.localizedDescription)")
            return
        }

        videoFileURL = outputFileURL
        print("✅ Finished recording to: \(outputFileURL)")
        saveVideoToPhotos(url: outputFileURL)
    }
}
