//
//  CharacterProfileViewWithFunctions.swift
//  Video Game App
//
//  Created by Mike K on 8/18/25.
//

import SwiftUI
import Supabase


struct CharacterProfileView: View {
    @AppStorage("accentColorName") private var accentColorName: String = "blue"
    @State private var profileImage: Image? = Image(systemName: "person.circle")
    @State private var name = ""

    // Store original values for cancel
    @State private var originalName = ""

    @EnvironmentObject var session: SessionStore

    @State private var showAlert = false
    @State private var usernameAvailable = true
    @State private var isEditing = false
    @State private var showProfilePhotoPicker = false
    @State private var showFullScreenPhoto = false
    
    @EnvironmentObject var viewModel: GalleryViewModel
    let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 3)
    let spacing: CGFloat = 2
    
    let gridColumns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]
    
    var itemWidth: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        return (screenWidth - 2 * spacing) / 3
    }

    var body: some View {
        NavigationView {
            GeometryReader { proxy in
                // We’ll give the grid 2pt padding on each side and subtract it from the math.
                let columns = gridColumns
                let horizontalOuterPadding: CGFloat = spacing // matches .padding(.horizontal, spacing)
                let totalInteritemSpacing = spacing * CGFloat(columns.count - 1)
                let contentWidth = proxy.size.width - (horizontalOuterPadding * 2)
                let itemWidth = (contentWidth - totalInteritemSpacing) / CGFloat(columns.count)
                ZStack{
                    ScrollView {
                        VStack(spacing: 20) {
                            
                            VStack{
                                HStack(alignment: .top){
                                    // Profile photo with edit button
                                    ZStack(alignment: .bottomTrailing) {
                                        profileImage?
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 85, height: 85)
                                            .foregroundColor(accentColorName.toColor())
                                            .clipShape(Circle())
                                            .overlay(
                                                Circle()
                                                    .stroke(accentColorName.toColor(), lineWidth: 3)
                                            )
                                            .shadow(radius: 5)
                                            .onTapGesture {
                                                showFullScreenPhoto = true
                                            }
                                        
                                        // Edit button overlay
                                        Button(action: {
                                            showProfilePhotoPicker = true
                                        }) {
                                            Image(systemName: "plus.circle.fill")
                                                .font(.system(size: 24))
                                                .foregroundColor(accentColorName.toColor())
                                                .background(Color.white)
                                                .clipShape(Circle())
                                        }
                                        .offset(x: 5, y: 5)
                                    }
                                    Spacer()
                                    
                                    
//                                    NavigationLink(destination: Settings()) {
//                                        Image(systemName: "gear")
//                                            .resizable()
//                                            .frame(width: 26, height: 26)
//                                        //                            .foregroundColor(accentColorName.toColor())
//                                            .foregroundColor(.gray)
//                                    }
                                    
                                }
                                .padding()
                                
                                // Fields
                                Group {
                                    editableField("Username", text: $name)
                                }
                                
                                
                                if isEditing {
                                    Button(action: {
                                        restoreOriginalValues()
                                        isEditing = false
                                    }) {
                                        Text("Cancel")
                                            .frame(maxWidth: .infinity, minHeight: 44)
                                            .background(Color.gray)
                                            .foregroundColor(.white)
                                            .cornerRadius(8)
                                    }
                                    .padding(.horizontal)
                                }
                                
                                
                                Button(action: {
                                    if isEditing {
                                        Task {
                                            if await isUsernameAvailable(name) {
                                                await saveProfile()
                                                isEditing = false
                                            } else {
                                                await MainActor.run { showAlert = true }
                                            }
                                        }
                                    } else {
                                        isEditing = true
                                    }
                                }) {
                                    Text(isEditing ? "Save Profile" : "Edit Profile")
                                        .frame(maxWidth: .infinity, minHeight: 44)
                                        .foregroundColor(.white)
                                    //                            .background(isEditing && (name.isEmpty || !usernameAvailable) ? Color.gray : Color.blue)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                }
                                .alert("Username Taken", isPresented: $showAlert) {
                                    Button("OK", role: .cancel) {}
                                } message: {
                                    Text("Please choose a different username.")
                                }
                                .disabled(isEditing && (name.isEmpty || !usernameAvailable))
                                .padding(.horizontal)
                                
                                HStack{
                                    Spacer()
                                    Button("Log Out") {
                                        Task { await session.signOut() } // no MainActor.run needed
                                    }
                                    .foregroundColor(.gray)
                                }
                                .padding(.horizontal)
                            }
                            
                            LazyVGrid(columns: columns, spacing: spacing) {
                                // Show loading placeholders first
                                ForEach(viewModel.loadingPhotos, id: \.self) { _ in
                                    LoadingPhotoPlaceholder(width: itemWidth, height: 200)
                                }
                                
                                // Show actual images with titles and descriptions
                                ForEach(Array(viewModel.galleryImages.enumerated()), id: \.element) { index, url in
                                    let photo = viewModel.getPhoto(for: url)
                                    NavigationLink(destination: GalleryDetailView(
                                        imageURL: url,
                                        photo: photo
                                    )
                                        .environmentObject(viewModel)) {
                                            ZStack(alignment: .bottomLeading) {
                                                // Image
                                                CachedAsyncImage(url: URL(string: url)) { image in
                                                    image
                                                        .resizable()
                                                        .scaledToFill()
                                                        .frame(width: itemWidth, height: 200)
                                                        .clipped()
                                                } placeholder: {
                                                    ProgressView()
                                                        .frame(width: itemWidth, height: 200)
                                                }
                                                
                                                // Black gradient
                                                LinearGradient(
                                                    colors: [Color.black.opacity(0.8), .clear],
                                                    startPoint: .bottom,
                                                    endPoint: .top
                                                )
                                                .frame(height: 70) // height of gradient overlay
                                                .frame(maxWidth: .infinity, alignment: .bottom)
                                                
                                                // Title text
                                                if let title = photo?.title, !title.isEmpty {
                                                    Text(title)
                                                        .font(.caption).bold()
                                                        .foregroundColor(.white)
                                                        .lineLimit(2)
                                                        .padding([.horizontal, .bottom], 6)
                                                }
                                                
                                                //                                            // Description below image (only show if exists)
                                                //                                            if let description = photo?.description, !description.isEmpty {
                                                //                                                Text(description)
                                                //                                                    .font(.caption2)
                                                //                                                    .foregroundColor(.secondary)
                                                //                                                    .lineLimit(2)
                                                //                                                    .multilineTextAlignment(.leading)
                                                //                                            }
                                                
                                            }
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                }
                            }
                            // Use horizontal padding equal to `spacing` so the math lines up
                            .padding(.horizontal, horizontalOuterPadding)
                            .padding(.bottom) // optional
                            
                            // Dummy stats for now
                            PlayerStatsView(level: 1)
                            
                        }
                        
                    }
                }
            }
        }
        .navigationTitle("Character Profile")
        .task {
            await checkProfileExists()
            await loadProfile()  // only load profile if it exists
        }
        .sheet(isPresented: $showProfilePhotoPicker) {
            ProfilePhotoPickerView { imageURL in
                // Update the profile image when a new photo is selected
                Task {
                    await loadProfileImage(from: imageURL)
                }
            }
        }
        .fullScreenCover(isPresented: $showFullScreenPhoto) {
            FullScreenPhotoView(image: profileImage, accentColor: accentColorName.toColor())
        }

    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    

    // Save current values as original
    func saveOriginalValues() {
        originalName = name
    }

    // Restore original values on cancel
    func restoreOriginalValues() {
        name = originalName
    }

    @ViewBuilder
    func editableField(_ label: String, text: Binding<String>) -> some View {
        if isEditing {
            TextField(label, text: text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
        } else {
            HStack {
                Text("\(label):")
                    .bold()
                Text(text.wrappedValue)
                Spacer()
            }
            .padding(.horizontal)
            
            HStack {
                Text("Age:")
                    .bold()
                Text("41")
                Spacer()
            }
            .padding(.horizontal)
            HStack {
                Text("Location:")
                    .bold()
                Text("California")
                Spacer()
            }
            .padding(.horizontal)
            HStack {
                Text("Occupation:")
                    .bold()
                Text("Unemployed Software Engineer")
                Spacer()
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Load profile from Supabase

    func saveProfile() async {
        guard let userID = session.user?.id else {
            print("No user ID found")
            return
        }

        do {
            print("Updating username to:", name)
            print("Attempting to update profile for user: \(userID)")

            // Save the response to a variable
            let response = try await supabase.database
                .from("profiles")
                .update(["username": name], returning: .representation)
                .eq("id", value: userID)
                .execute()

            // Now you can safely access response.data
            print("Updated row:", response.data ?? "nil")
            print("Profile updated successfully!")

        } catch {
            print("Error updating profile: \(error.localizedDescription)")
        }
    }

    func isUsernameAvailable(_ username: String) async -> Bool {
        guard let currentUserID = session.user?.id else { return false }

        do {
            let response = try await supabase.database
                .from("profiles")
                .select("*")
                .eq("username", value: username)
                .execute()

            if let users = try? JSONDecoder().decode([UserProfile].self, from: response.data) {
                // true if no other users have this username
                return users.allSatisfy { $0.id == currentUserID }
            }
        } catch {
            print("Error checking username:", error.localizedDescription)
        }
        return false
    }


    func checkProfileExists() async {
        guard let userID = session.user?.id else { return }

        do {
            let response = try await supabase.database
                .from("profiles")
                .select()
                .eq("id", value: userID)
                .single()
                .execute()

            if response.data == nil {
                // Profile row missing — force logout
                await MainActor.run {
                    Task { await session.signOut() }
                }
            }
        } catch {
            print("Error checking profile: \(error.localizedDescription)")
            // Optional: log out on error if you want stricter safety
        }
    }

    func loadProfile() async {
        guard let userID = session.user?.id else { return }

        do {
            let response = try await supabase.database
                .from("profiles")
                .select("*")
                .eq("id", value: userID)
                .single()
                .execute()

            // Decode directly from response.data
            let userProfile = try JSONDecoder().decode(UserProfile.self, from: response.data)

            await MainActor.run {
                name = userProfile.username ?? ""
                saveOriginalValues()

                if let profileURL = userProfile.profilePhotoURL {
                    Task {
                        await loadProfileImage(from: profileURL)
                    }
                }
            }
        } catch {
            print("Failed to load profile:", error)
        }
    }
    
    func loadProfileImage(from urlString: String) async {
        guard let url = URL(string: urlString) else { return }
        
        do {
            let imageData = try Data(contentsOf: url)
            if let uiImage = UIImage(data: imageData) {
                await MainActor.run {
                    profileImage = Image(uiImage: uiImage)
                }
            }
        } catch {
            print("Failed to load profile image: \(error)")
        }
    }




}

// MARK: - Full Screen Photo View
struct FullScreenPhotoView: View {
    let image: Image?
    let accentColor: Color
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                    }
                    .padding()
                }
                
                Spacer()
                
                image?
                    .resizable()
                    .scaledToFit()
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(accentColor, lineWidth: 4)
                    )
                    .shadow(radius: 10)
                    .padding()
                
                Spacer()
            }
        }
    }
}
