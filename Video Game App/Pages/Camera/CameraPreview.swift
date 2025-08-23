//
//  CameraPreview.swift
//  Video Game App
//
//  Created by Mike K on 8/18/25.
//

import SwiftUI
import AVFoundation

// MARK: - CameraPreview
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    let position: AVCaptureDevice.Position   // <-- add
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        context.coordinator.previewLayer = previewLayer

        return view
    }


    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            context.coordinator.previewLayer?.frame = uiView.bounds

            if let connection = context.coordinator.previewLayer?.connection {
                // Mirror only for front camera to match user expectation
                if let input = session.inputs.first as? AVCaptureDeviceInput {
                    connection.automaticallyAdjustsVideoMirroring = false
                    connection.isVideoMirrored = (input.device.position == .front)
                }
            }
        }
    }
    
    // Force portrait (or compute from interface orientation) and mirror only on front
    private func applyOrientationAndMirroring(previewLayer: AVCaptureVideoPreviewLayer) {
        if let connection = previewLayer.connection {
            // If you want dynamic rotation, map from windowScene.interfaceOrientation instead
            connection.videoOrientation = .portrait
            connection.automaticallyAdjustsVideoMirroring = false
            connection.isVideoMirrored = (position == .front)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }
    
    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
    }
}
