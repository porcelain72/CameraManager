
import XCTest
@testable import CameraManager

final class CameraManagerTests: XCTestCase {

    func testDefaultSettings() {
        let settings = VideoSettings()
        XCTAssertEqual(settings.position, .back)
        XCTAssertEqual(settings.frameRate, 30)
        XCTAssertEqual(settings.avPreset, .hd1920x1080)
    }

    func testCustomSettings() {
        let settings = VideoSettings(position: .front, resolution: .hd1280x720, frameRate: 60)
        XCTAssertEqual(settings.position, .front)
        XCTAssertEqual(settings.frameRate, 60)
        XCTAssertEqual(settings.avPreset, .hd1280x720)
    }
}

