import SwiftUI
import AVFoundation
import UIKit

// MARK: - CameraButtonView
struct CameraButtonView: View {
    @StateObject private var cameraService = CameraService()
    @State private var selectedUIImage: UIImage?
    @State private var showLibraryPicker = false
    @State private var navigateToPhotoReview = false
    @EnvironmentObject var galleryViewModel: GalleryViewModel
    @EnvironmentObject var notificationManager: GlobalNotificationManager

    // 1️⃣ Add a state variable for selected tags
    @State private var selectedTag: String? = nil

    // 3️⃣ Add custom positive prompt for testing
    @State private var customPositivePrompt: String = ""

    // 2️⃣ Your tags array
    let tags = ["📓 Daily Journal", "⚔️ Quests", "🥪 Rations", "🗺️ Map", "📦 Inventory"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {

                    // Live Camera
                    CameraPreview(session: cameraService.session, position: cameraService.cameraPosition)
                        .cornerRadius(12)
                        .shadow(radius: 6)
                        .frame(height: UIScreen.main.bounds.height * 0.55)
                        .padding(.horizontal)

                    Spacer()

                    // Buttons: Camera - Photo Library - Clear
                    HStack(spacing: 10) {

                        // Photo library button
                        Button {
                            showLibraryPicker = true
                        } label: {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 18))
                                .padding(12)
                                .background(Color(UIColor.systemGray6))
                                .foregroundColor(.primary)
                                .clipShape(Circle())
                        }
                        .accessibilityLabel("Choose from photo library")

                        // Camera capture button
                        Button {
                            cameraService.capturePhoto()
                        } label: {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 22))
                                .padding(24)
                                .background(Color.accentColor)
                                .foregroundColor(.primary)
                                .clipShape(Circle())
                        }

                        // Reverse / switch camera button
                        Button {
                            cameraService.switchCamera()
                        } label: {
                            Image(systemName: "arrow.triangle.2.circlepath.camera")
                                .font(.system(size: 18, weight: .semibold))
                                .padding(12)
                                .background(Color(UIColor.systemGray6))
                                .clipShape(Circle())
                                .shadow(radius: 3)
                        }
                        .accessibilityLabel("Switch camera")
                        .allowsHitTesting(true)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                    Spacer(minLength: 120)
                }
            }
            .onAppear {
                cameraService.startSession()
            }
            .onDisappear {
                cameraService.stopSession()
            }
            .onChange(of: cameraService.capturedImage) { newImage in
                if newImage != nil {
                    navigateToPhotoReview = true
                }
            }
            .sheet(isPresented: $showLibraryPicker) {
                PhotoLibraryPickerView(isPresented: $showLibraryPicker, selectedImage: $cameraService.capturedImage)
            }
            .background(
                photoReviewNavigationLink
            )
        }
    }
    
    // MARK: - Computed Properties
    private var photoReviewNavigationLink: some View {
        NavigationLink(
            destination: photoReviewDestination,
            isActive: $navigateToPhotoReview
        ) {
            EmptyView()
        }
    }
    
    private var photoReviewDestination: some View {
        Group {
            if let capturedImage = cameraService.capturedImage {
                PhotoReviewView(capturedImage: capturedImage)
                .environmentObject(galleryViewModel)
                .environmentObject(notificationManager)
                .onDisappear {
                    // Reset the captured image when the review page is dismissed
                    cameraService.capturedImage = nil
                }
            }
        }
    }
}


