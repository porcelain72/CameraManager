import AVFoundation
import Photos
import UIKit

public final class CameraService: NSObject, ObservableObject {
    private let session = AVCaptureSession()
    private var videoOutput = AVCaptureMovieFileOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var currentDevice: AVCaptureDevice?
    private var videoFileURL: URL?

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

        // Add output
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }

        session.commitConfiguration()
    }

    public func startSession() {
        if !session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                self.session.startRunning()
            }
        }
    }

    public func stopSession() {
        if session.isRunning {
            session.stopRunning()
        }
    }

    public func startRecording() {
        guard !isRecording else { return }

        let tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
        let fileName = UUID().uuidString + ".mov"
        let fileURL = tempDirectory.appendingPathComponent(fileName)

        videoOutput.startRecording(to: fileURL, recordingDelegate: self)
        isRecording = true
    }

    public func stopRecording() {
        guard isRecording else { return }
        videoOutput.stopRecording()
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
    public func fileOutput(_ output: AVCaptureFileOutput,
                           didFinishRecordingTo outputFileURL: URL,
                           from connections: [AVCaptureConnection],
                           error: Error?) {
        isRecording = false
        videoFileURL = outputFileURL

        if let error = error {
            print("❌ Recording error: \(error.localizedDescription)")
            return
        }

        saveVideoToPhotos(url: outputFileURL)
    }
}

