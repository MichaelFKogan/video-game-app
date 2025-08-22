////
////  CharacterProfileViewWithFunctions.swift
////  Video Game App
////
////  Created by Mike K on 8/18/25.
////
//
//import SwiftUI
//import Supabase
//
//struct UserProfile: Codable {
//    let id: String
//    let username: String
//    let profilePhotoURL: String?
//}
//
//
//struct CharacterProfileView: View {
//    @State private var profileImage: Image? = Image(systemName: "person.circle")
//    @State private var name = ""
//    
//    // Store original values for cancel
//    @State private var originalName = ""
//    
//    @EnvironmentObject var session: SessionStore
//    
//    @State private var showAlert = false
//    @State private var usernameAvailable = true
//    @State private var isEditing = false
//    
//    var body: some View {
//        ScrollView {
//            VStack(spacing: 20) {
//                HStack{
//                    Spacer()
//                    Button("Log Out") {
//                        Task { await session.signOut() } // no MainActor.run needed
//                    }
//                }
//                .padding()
//                
//                // Profile photo
//                profileImage?
//                    .resizable()
//                    .scaledToFill()
//                    .frame(width: 120, height: 120)
//                    .clipShape(Circle())
//                    .shadow(radius: 5)
//                    .padding(.top, 20)
//                
//                // Fields
//                Group {
//                    editableField("Username", text: $name)
//                }
//                
//                
//                if isEditing {
//                    Button(action: {
//                        restoreOriginalValues()
//                        isEditing = false
//                    }) {
//                        Text("Cancel")
//                            .frame(maxWidth: .infinity, minHeight: 44)
//                            .background(Color.gray)
//                            .foregroundColor(.white)
//                            .cornerRadius(8)
//                    }
//                    .padding(.horizontal)
//                }
//
//                
//                Button(action: {
//                    if isEditing {
//                        Task {
//                            if await isUsernameAvailable(name) {
//                                await saveProfile()
//                                isEditing = false
//                            } else {
//                                await MainActor.run { showAlert = true }
//                            }
//                        }
//                    } else {
//                        isEditing = true
//                    }
//                }) {
//                    Text(isEditing ? "Save Profile" : "Edit Profile")
//                        .frame(maxWidth: .infinity, minHeight: 44)
//                        .foregroundColor(.white)
//                        .background(isEditing && (name.isEmpty || !usernameAvailable) ? Color.gray : Color.blue)
//                        .cornerRadius(8)
//                }
//                .alert("Username Taken", isPresented: $showAlert) {
//                    Button("OK", role: .cancel) {}
//                } message: {
//                    Text("Please choose a different username.")
//                }
//                .disabled(isEditing && (name.isEmpty || !usernameAvailable))
//                .padding(.horizontal)
//
//                
//                Spacer()
//            }
//        }
//        .navigationTitle("Character Profile")
//        .task {
//            await checkProfileExists()
//            await loadProfile()  // only load profile if it exists
//        }
//
//    }
//        
//    // Save current values as original
//    func saveOriginalValues() {
//        originalName = name
//    }
//    
//    // Restore original values on cancel
//    func restoreOriginalValues() {
//        name = originalName
//    }
//    
//    @ViewBuilder
//    func editableField(_ label: String, text: Binding<String>) -> some View {
//        if isEditing {
//            TextField(label, text: text)
//                .textFieldStyle(RoundedBorderTextFieldStyle())
//                .padding(.horizontal)
//        } else {
//            HStack {
//                Text("\(label):")
//                    .bold()
//                Text(text.wrappedValue)
//                Spacer()
//            }
//            .padding(.horizontal)
//        }
//    }
//    
//    // MARK: - Load profile from Supabase
//    
//    func saveProfile() async {
//        guard let userID = session.user?.id.uuidString else {
//            print("No user ID found")
//            return
//        }
//
//        do {
//            print("Updating username to:", name)
//            print("Attempting to update profile for user: \(userID)")
//            
//            // Save the response to a variable
//            let response = try await supabase.database
//                .from("profiles")
//                .update(["username": name], returning: .representation)
//                .eq("id", value: userID)
//                .execute()
//            
//            // Now you can safely access response.data
//            print("Updated row:", response.data ?? "nil")
//            print("Profile updated successfully!")
//
//        } catch {
//            print("Error updating profile: \(error.localizedDescription)")
//        }
//    }
//    
//    func isUsernameAvailable(_ username: String) async -> Bool {
//        guard let currentUserID = session.user?.id.uuidString else { return false }
//
//        do {
//            let response = try await supabase.database
//                .from("profiles")
//                .select("*")
//                .eq("username", value: username)
//                .execute()
//
//            if let users = try? JSONDecoder().decode([UserProfile].self, from: response.data) {
//                // true if no other users have this username
//                return users.allSatisfy { $0.id == currentUserID }
//            }
//        } catch {
//            print("Error checking username:", error.localizedDescription)
//        }
//        return false
//    }
//
//
//    func checkProfileExists() async {
//        guard let userID = session.user?.id.uuidString else { return }
//        
//        do {
//            let response = try await supabase.database
//                .from("profiles")
//                .select()
//                .eq("id", value: userID)
//                .single()
//                .execute()
//            
//            if response.data == nil {
//                // Profile row missing — force logout
//                await MainActor.run {
//                    Task { await session.signOut() }
//                }
//            }
//        } catch {
//            print("Error checking profile: \(error.localizedDescription)")
//            // Optional: log out on error if you want stricter safety
//        }
//    }
//
//    func loadProfile() async {
//        guard let userID = session.user?.id.uuidString else { return }
//
//        do {
//            let response = try await supabase.database
//                .from("profiles")
//                .select("*")
//                .eq("id", value: userID)
//                .single()
//                .execute()
//
//            // Decode directly from response.data
//            let userProfile = try JSONDecoder().decode(UserProfile.self, from: response.data)
//
//            await MainActor.run {
//                name = userProfile.username
//                saveOriginalValues()
//                
//                if let profileURL = userProfile.profilePhotoURL,
//                   let url = URL(string: profileURL),
//                   let imageData = try? Data(contentsOf: url),
//                   let uiImage = UIImage(data: imageData) {
//                    profileImage = Image(uiImage: uiImage)
//                }
//            }
//        } catch {
//            print("Failed to load profile:", error)
//        }
//    }
//
//
//    
//    
//}
