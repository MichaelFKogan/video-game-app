////
////  CharacterProfileViewNoFunctions.swift
////  Video Game App
////
////  Created by Mike K on 8/18/25.
////
//
//import SwiftUI
//import Supabase
//
//
//struct CharacterProfileView: View {
//    @EnvironmentObject var session: SessionStore
//    @StateObject private var viewModel: UserProfileViewModel
//    
//    init(session: SessionStore) {
//        _viewModel = StateObject(wrappedValue: UserProfileViewModel(session: session))
//    }
//    
//    var body: some View {
//        ScrollView {
//            VStack(spacing: 20) {
//                HStack {
//                    Spacer()
//                    Button("Log Out") {
//                        Task { await session.signOut() }
//                    }
//                }
//                .padding()
//                
//                viewModel.profileImage?
//                    .resizable()
//                    .scaledToFill()
//                    .frame(width: 120, height: 120)
//                    .clipShape(Circle())
//                    .shadow(radius: 5)
//                    .padding(.top, 20)
//                
//                viewModel.editableField("Username")
//                
//                if viewModel.isEditing {
//                    Button("Cancel") {
//                        viewModel.restoreOriginalValues()
//                        viewModel.isEditing = false
//                    }
//                    .frame(maxWidth: .infinity, minHeight: 44)
//                    .background(Color.gray)
//                    .foregroundColor(.white)
//                    .cornerRadius(8)
//                    .padding(.horizontal)
//                }
//                
//                Button(viewModel.isEditing ? "Save Profile" : "Edit Profile") {
//                    if viewModel.isEditing {
//                        Task {
//                            if await viewModel.isUsernameAvailable(viewModel.name) {
//                                await viewModel.saveProfile()
//                                viewModel.isEditing = false
//                            } else {
//                                viewModel.showAlert = true
//                            }
//                        }
//                    } else {
//                        viewModel.isEditing = true
//                    }
//                }
//                .frame(maxWidth: .infinity, minHeight: 44)
//                .foregroundColor(.white)
//                .background(viewModel.isEditing && viewModel.name.isEmpty ? Color.gray : Color.blue)
//                .cornerRadius(8)
//                .alert("Username Taken", isPresented: $viewModel.showAlert) {
//                    Button("OK", role: .cancel) {}
//                } message: {
//                    Text("Please choose a different username.")
//                }
//                .padding(.horizontal)
//                
//                Spacer()
//            }
//        }
//        .navigationTitle("Character Profile")
//        .task {
//            await viewModel.checkProfileExists()
//            await viewModel.loadProfile()
//        }
//    }
//}
