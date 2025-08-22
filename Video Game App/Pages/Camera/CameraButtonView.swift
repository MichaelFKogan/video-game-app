import SwiftUI
import AVFoundation
import UIKit

// MARK: - CameraButtonView
struct CameraButtonView: View {
    @StateObject private var cameraService = CameraService()
    @State private var selectedUIImage: UIImage?
    @State private var showLibraryPicker = false
    
    // 1️⃣ Add a state variable for selected tags
    @State private var selectedTag: String? = nil

    // 2️⃣ Your tags array
    let tags = ["📓 Daily Journal", "⚔️ Quests", "🥪 Rations", "🗺️ Map", "📦 Inventory"]

    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                
//                // Page Title
//                HStack {
//                    Text("Camera")
//                        .font(.largeTitle)
//                        .fontWeight(.bold)
//                    Spacer()
//                }
//                .padding()

            // Live Camera
                ZStack {
                    if cameraService.capturedImage == nil {
                        CameraPreview(session: cameraService.session)
                            .cornerRadius(12)
                            .shadow(radius: 6)
                    } else {
                        Image(uiImage: cameraService.capturedImage!)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(12)
                            .shadow(radius: 6)
                    }
                }
                .frame(height: UIScreen.main.bounds.height * 0.55)
                .padding(.horizontal)
                
                

                // Buttons: Camera - Photo Library - Clear
                HStack(alignment: .top) {
                    
                    Spacer()
                    
                    HStack{
                        // Photo library button
                        Button {
                            showLibraryPicker = true
                        } label: {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 18))
                                .padding(12)
                                .background(Color(UIColor.systemGray6)).opacity(cameraService.capturedImage == nil ? 1 : 0)
                                .foregroundColor(.primary).opacity(cameraService.capturedImage == nil ? 1 : 0)
                                .clipShape(Circle())
                        }
                        .accessibilityLabel("Choose from photo library")
                        
                        if cameraService.capturedImage == nil {
                            
                            // Camera capture button
                            Button {
                                cameraService.capturePhoto()
                            } label: {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 22))
                                    .padding(20)
                                    .background(Color(UIColor.systemGray6))
                                    .foregroundColor(.primary)
                                    .clipShape(Circle())
                            }
                        }else{
                            
                    // ACCEPT PHOTO BUTTON
                        // SEND TO API
                            Button {
                                guard let raw = cameraService.capturedImage else { return }

                                // Make pixels upright and portrait before sending
                                let normalized = raw.normalizedOrientation()
                                let portrait = normalized.centerCropped(toAspect: 3.0/4.0) // choose 9/16, 2/3, etc.
                                let finalImage = portrait.resized(maxLongSide: 1536)        // optional but tidy
                                
                                let runwareAPI = RunwareAPI()
                                
                                RunwareAPI().sendImageToRunware(image: finalImage) { result in
                                    DispatchQueue.main.async {
                                        switch result {
                                        case .success(let runwareURLString):
                                            print("✅ Got transformed image: \(runwareURLString)")
                                            
                                            guard let runwareURL = URL(string: runwareURLString) else {
                                                print("❌ Invalid URL string from Runware")
                                                return
                                            }
                                            
                                            // Save into Supabase
                                            Task {
                                                do {
                                                    let service = PhotoService(client: supabase)
                                                    let signedURL = try await service.saveRunwareImage(
                                                        runwareURL: runwareURL,
                                                        description: selectedTag ?? "Untitled"
                                                    )
                                                    print("✅ Uploaded & saved. Signed URL: \(signedURL)")
                                                    // 👉 later you can push signedURL into your Gallery view model
                                                } catch {
                                                    print("❌ Supabase upload failed: \(error)")
                                                }
                                            }
                                            
                                        case .failure(let error):
                                            print("❌ Runware error: \(error.localizedDescription)")
                                        }
                                    }
                                }
                            } label: {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 22))
                                    .fontWeight(.bold)
                                    .padding(18)
                                    .background(cameraService.capturedImage == nil ? Color.gray : Color.accentColor)
                                    .foregroundColor(.white)
                                    .clipShape(Circle())
                            }
                            .accessibilityLabel("Accept photo")
                            .disabled(cameraService.capturedImage == nil)

                            
                        }
                            
                            Button {
                                cameraService.capturedImage = nil
                            } label: {
                                // Photo library button
                                Image(systemName: "xmark")
                                    .font(.system(size: 16))
                                    .fontWeight(.bold)
                                    .padding(12)
                                    .background(Color(UIColor.systemGray6).opacity(cameraService.capturedImage == nil ? 0 : 1))
                                    .foregroundColor(.red.opacity(cameraService.capturedImage == nil ? 0 : 1))
                                    .clipShape(Circle())
                            }
                        
                    }

                    Spacer()
                    
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                Divider()
                
                
                
                
                
                // Quest Buttons
//                ScrollView(.horizontal, showsIndicators: false) {
//                    HStack(spacing: 12) {
//                        ForEach(tags, id: \.self) { tag in
//                            Button(action: {
//                                // Toggle selection
//                                if selectedTag == tag {
//                                    selectedTag = nil
//                                } else {
//                                    selectedTag = tag
//                                }
//                            }) {
//                                Text(tag)
//                                    .font(.subheadline)
//                                    .fontWeight(.bold)
//                                    .padding(.vertical, 16)
//                                    .padding(.horizontal, 14)
//                                    .background(
//                                        selectedTag == tag ? Color.accentColor : Color(UIColor.systemGray6)
//                                    )
//                                    .foregroundColor(selectedTag == tag ? .white : .primary)
//                                    .clipShape(Rectangle())
//                                    .cornerRadius(4)
//                            }
//                        }
//                    }
//                    .padding(.horizontal)
//                    .padding(.vertical, 8)
                
//                }
                
                
                

                Spacer()
            }
            .onAppear {
                cameraService.startSession()
            }
            .onDisappear {
                cameraService.stopSession()
            }
            .sheet(isPresented: $showLibraryPicker) {
                PhotoLibraryPickerView(isPresented: $showLibraryPicker, selectedImage: $cameraService.capturedImage)
            }
        }
    }
}
