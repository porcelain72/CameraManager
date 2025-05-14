# CameraManager

A Swift package for modular AVFoundation video capture in iOS apps. Designed for minimal SwiftUI integration and high-speed startup.

## Features

- Instant camera session setup
- Start/stop video recording
- Save videos to Photos
- Supports camera selection, resolution, and frame rate
- No third-party dependencies

## Requirements

- iOS 16+
- Swift 5.7+

## Installation

### Swift Package Manager (Local)

1. Clone or download this package into your project folder
2. In Xcode, go to `File > Add Packages...`
3. Select `Add Local...` and choose the `CameraManager` directory

## Usage

```swift
import CameraManager

let settings = VideoSettings(position: .back, resolution: .hd1920x1080, frameRate: 30)
let cameraService = CameraService(settings: settings)

