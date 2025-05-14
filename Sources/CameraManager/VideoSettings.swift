import AVFoundation

public struct VideoSettings {
    public var position: AVCaptureDevice.Position
    public var resolution: Resolution
    public var frameRate: Int

    public init(position: AVCaptureDevice.Position = .back,
                resolution: Resolution = .hd1920x1080,
                frameRate: Int = 30) {
        self.position = position
        self.resolution = resolution
        self.frameRate = frameRate
    }

    public var avPreset: AVCaptureSession.Preset {
        switch resolution {
        case .hd1280x720: return .hd1280x720
        case .hd1920x1080: return .hd1920x1080
        case .hd4K3840x2160: return .hd4K3840x2160
        }
    }

    public enum Resolution : String {
        case hd1280x720
        case hd1920x1080
        case hd4K3840x2160
    }
}

