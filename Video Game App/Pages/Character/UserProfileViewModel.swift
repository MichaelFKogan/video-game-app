////
////  UserProfileViewModel.swift
////  Video Game App
////
////  Created by Mike K on 8/18/25.
////
//
//import Foundation
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
//@MainActor
//class UserProfileViewModel: ObservableObject {
//    @Published var name: String = ""
//    @Published var profileImage: Image? = Image(systemName: "person.circle")
//    
//    private var originalName: String = ""
//    
//    @Published var showAlert = false
//    @Published var usernameAvailable = true
//    @Published var isEditing = false
//    
//    private let session: SessionStore
//    
//    init(session: SessionStore) {
//        self.session = session
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
//    func editableField(_ label: String) -> some View {
//        HStack {
//            Text("\(label):")
//                .bold()
//            Text(name)
//            Spacer()
//        }
//        .padding(.horizontal)
//    }
//    
//    // MARK: - Supabase Functions
//    
//    func saveProfile() async {
//        guard let userID = session.user?.id.uuidString else { return }
//        
//        do {
//            let response = try await supabase.database
//                .from("profiles")
//                .update(["username": name], returning: .representation)
//                .eq("id", value: userID)
//                .execute()
//            
//            print("Updated row:", response.data ?? "nil")
//        } catch {
//            print("Error updating profile:", error.localizedDescription)
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
//                Task { await session.signOut() }
//            }
//        } catch {
//            print("Error checking profile: \(error.localizedDescription)")
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
//            let userProfile = try JSONDecoder().decode(UserProfile.self, from: response.data)
//
//            name = userProfile.username
//            saveOriginalValues()
//            
//            if let profileURL = userProfile.profilePhotoURL,
//               let url = URL(string: profileURL),
//               let imageData = try? Data(contentsOf: url),
//               let uiImage = UIImage(data: imageData) {
//                profileImage = Image(uiImage: uiImage)
//            }
//        } catch {
//            print("Failed to load profile:", error)
//        }
//    }
//}
