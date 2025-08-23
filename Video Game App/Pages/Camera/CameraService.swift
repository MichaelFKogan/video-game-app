import SwiftUI
import AVFoundation
import UIKit

import SwiftUI
import AVFoundation
import UIKit

@MainActor
final class CameraService: NSObject, ObservableObject {
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var currentInput: AVCaptureDeviceInput?
    @Published var capturedImage: UIImage?
    @Published private(set) var cameraPosition: AVCaptureDevice.Position = .back

    func startSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo

        configureInput(position: .back)

        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            photoOutput.isHighResolutionCaptureEnabled = true
        }

        session.commitConfiguration()

        // startRunning blocks; do it off the main thread
        DispatchQueue.global(qos: .userInitiated).async { [weak session] in
            session?.startRunning()
        }
    }

    func stopSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak session] in
            session?.stopRunning()
        }
    }

    private func configureInput(position: AVCaptureDevice.Position) {
        if let old = currentInput { session.removeInput(old) }

        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: position
        )
        guard let device = discovery.devices.first,
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else { return }

        session.addInput(input)
        currentInput = input
        cameraPosition = position     // <-- add this
    }

    func switchCamera() {
        session.beginConfiguration()
        let newPos: AVCaptureDevice.Position = (currentInput?.device.position == .back) ? .front : .back
        configureInput(position: newPos)
        session.commitConfiguration()
    }

    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        if let connection = photoOutput.connection(with: .video) {
            connection.videoOrientation = .portrait
            connection.isVideoMirrored = false // preview mirrors instead
        }
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
}

extension CameraService: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        guard error == nil,
              let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else { return }
        capturedImage = image
    }
}
