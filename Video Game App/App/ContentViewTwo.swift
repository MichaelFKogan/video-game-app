////
////  ContentViewTwo.swift
////  Video Game App
////
////  Created by Mike K on 8/18/25.
////
//
//import SwiftUI
//
//struct ContentViewTwo: View {
//    @AppStorage("isDarkMode") private var isDarkMode = true
//    @AppStorage("accentColorName") private var accentColorName: String = "blue"
//    @State private var selectedTab = 0 // Start with Home tab
//    @State private var showCamera = false
//    
//    var body: some View {
//
//        ZStack {
//            TabView(selection: $selectedTab) {
//                // 🌃 Gallery / Home Tab
//                GalleryView()
//                    .tabItem {
//                        Label("Home", systemImage: "house")
//                    }
//                    .tag(0)
//                
//                // 📓 Daily Entries
//                DailyEntries()
//                    .tabItem {
//                        Label("Daily Journal", systemImage: "book.closed")
//                    }
//                    .tag(1)
//                
//                CameraButtonView() // <-- Camera page
//                    .tabItem { Label("", systemImage: "") }
//                    .tag(2)
//                
//                // 🛠️ Quests Tab
//                QuestView()
//                    .tabItem {
//                        Label("Quests", systemImage: "scroll")
//                    }
//                    .tag(3)
//                
//                // 👤 Character
//                CharacterProfileView()
//                    .tabItem {
//                        Label("Character", systemImage: "person.crop.circle")
//                    }
//                    .tag(4)
//                
////                // ⚙️ Settings
////                Settings()
////                    .tabItem {
////                        Label("Settings", systemImage: "gear")
////                    }
////                    .tag(4)
//                
//                
//                
//                //                // 🏠 Home Tab
//                //                Home()
//                //                .tabItem {
//                //                    Label("Home", systemImage: "house")
//                //                }
//                //                .tag(0)
//                
//                //                CameraButtonView()
//                //                .tabItem {
//                //                    Label("Camera", systemImage: "camera")
//                //                }
//                //                .tag(2)
//                
//                
////                // 📸 Empty Tab Placeholder for Camera
////                Color.clear
////                    .tabItem {
////                        Label("", systemImage: "")
////                    }
////                    .tag(2)
//                
//                
//                
//                //                // 🥪 Rations / Food
//                //                    VStack {
//                //                        Text("Rations")
//                //                            .font(.largeTitle)
//                //                    }
//                //                    .tabItem {
//                //                        Label("Rations", systemImage: "leaf") // fire or food icon vibes
//                //                    }
//                //                    .tag(3)
//                
//                //                // 🗺️ Map
//                //                    VStack {
//                //                        Text("Map")
//                //                            .font(.largeTitle)
//                //                    }
//                //                    .tabItem {
//                //                        Label("Map", systemImage: "map") // fire or food icon vibes
//                //                    }
//                //                    .tag(3)
//                
//                
//                //                // 👤 Character / 📊 Stats Tab
//                //                CharacterProfileView()
//                //                .tabItem {
//                //                    Label("Character", systemImage: "person.crop.circle")
//                //                }
//                //                .tag(4)
//                
//                
//                // 📸 Empty Tab Placeholder for Camera
//                //                Color.clear
//                //                    .tabItem {
//                //                        Label("", systemImage: "")
//                //                    }
//                //                    .tag(2)
//                
//                
//                //                // 📦 Inventory / ❤️‍🩹 Health Tab
//                //                VStack {
//                //                    Text("Inventory")
//                //                        .font(.largeTitle)
//                //                }
//                //                .tabItem {
//                //                    Label("Inventory", systemImage: "bag")
//                //                }
//                //                .tag(3)
//                
//            }
//            .accentColor(accentColorName.toColor())
//            .preferredColorScheme(isDarkMode ? .dark : .light) // apply dark/light mode
//            
//            // 📸 Floating Camera Button
//            VStack {
//                Spacer() // push to bottom
//                HStack {
//                    Spacer()
//                    
//                    Button(action: {
//                        selectedTab = 2
//                    }) {
//                        ZStack {
//                            Circle()
//                                .fill(accentColorName.toColor())
//                                .frame(width: 57, height: 57)
//                                .shadow(radius: 4)
//                            
//                            Image(systemName: "camera.fill")
//                                .resizable()
//                                .scaledToFit()
//                                .frame(width: 25, height: 25)
//                                .foregroundColor(isDarkMode ? .black : .white)
//                        }
//                    }
//                    .offset(y: -5)
//                    Spacer()
//                }
//            }
//            
//        }
//    }
//}
//
