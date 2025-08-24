// FEED INTEGRATION EXAMPLE
// This shows how to add the feed to your existing ContentView

import SwiftUI

// Example of how to modify your existing ContentView to add the feed
struct ContentViewWithFeed: View {
    
    @StateObject private var session = SessionStore()
    @StateObject private var galleryViewModel = GalleryViewModel(client: supabase)
    @StateObject private var notificationManager = GlobalNotificationManager()

    @AppStorage("isDarkMode") private var isDarkMode = true
    @AppStorage("accentColorName") private var accentColorName: String = "blue"
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            // Global notification overlay
            GlobalNotificationView(notificationManager: notificationManager)
            
            TabView(selection: $selectedTab) {
                
                // 🌃 Gallery / Home Tab (existing)
                AuthGuard {
                    GalleryView()
                        .environmentObject(galleryViewModel)
                }
                .tabItem {Label("Storyline", systemImage: "book.closed")}
                .tag(0)
                
                // 🆕 NEW: Public Feed Tab
                AuthGuard {
                    FeedView(client: SupabaseManager.shared.client)
                }
                .tabItem {Label("Feed", systemImage: "photo.on.rectangle.angled")}
                .tag(1)
                
                // 📓 Photo Albums (existing)
                AuthGuard {
                    GalleryView()
                        .environmentObject(galleryViewModel)
                }
                .tabItem {Label("Photo Albums", systemImage: "photo.on.rectangle")}
                .tag(2)
                
                // 🛠️ Quests Tab (existing)
                AuthGuard {
                    QuestView()
                }
                .tabItem {Label("Side Quests", systemImage: "scroll")}
                .tag(3)
                
                // 📷 Camera (existing)
                AuthGuard {
                    CameraButtonView()
                        .environmentObject(galleryViewModel)
                        .environmentObject(notificationManager)
                }
                .environmentObject(session)
                .tabItem { Label("Camera", systemImage: "camera") }
                .tag(4)
                
                // 👤 Character (existing)
                AuthGuard {
                    CharacterProfileView()
                }
                .tabItem {
                    Label("Character", systemImage: "person.crop.circle")
                }
                .tag(5)
                
            }
            .environmentObject(session)
            .accentColor(accentColorName.toColor())
            .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }
}

// ALTERNATIVE: Add feed as a modal/sheet instead of a tab
struct ContentViewWithFeedModal: View {
    
    @StateObject private var session = SessionStore()
    @StateObject private var galleryViewModel = GalleryViewModel(client: supabase)
    @StateObject private var notificationManager = GlobalNotificationManager()

    @AppStorage("isDarkMode") private var isDarkMode = true
    @AppStorage("accentColorName") private var accentColorName: String = "blue"
    @State private var selectedTab = 0
    @State private var showingFeed = false // Add this state
    
    var body: some View {
        ZStack {
            // Global notification overlay
            GlobalNotificationView(notificationManager: notificationManager)
            
            TabView(selection: $selectedTab) {
                
                // 🌃 Gallery / Home Tab (existing)
                AuthGuard {
                    GalleryView()
                        .environmentObject(galleryViewModel)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Feed") {
                                    showingFeed = true
                                }
                            }
                        }
                }
                .tabItem {Label("Storyline", systemImage: "book.closed")}
                .tag(0)
                
                // Your other existing tabs...
                // (same as before)
                
            }
            .environmentObject(session)
            .accentColor(accentColorName.toColor())
            .preferredColorScheme(isDarkMode ? .dark : .light)
            .sheet(isPresented: $showingFeed) {
                FeedView(client: SupabaseManager.shared.client)
            }
        }
    }
}

// ALTERNATIVE: Replace one of your existing tabs with the feed
struct ContentViewWithFeedReplacement: View {
    
    @StateObject private var session = SessionStore()
    @StateObject private var galleryViewModel = GalleryViewModel(client: supabase)
    @StateObject private var notificationManager = GlobalNotificationManager()

    @AppStorage("isDarkMode") private var isDarkMode = true
    @AppStorage("accentColorName") private var accentColorName: String = "blue"
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            // Global notification overlay
            GlobalNotificationView(notificationManager: notificationManager)
            
            TabView(selection: $selectedTab) {
                
                // 🌃 Gallery / Home Tab (existing)
                AuthGuard {
                    GalleryView()
                        .environmentObject(galleryViewModel)
                }
                .tabItem {Label("Storyline", systemImage: "book.closed")}
                .tag(0)
                
                // 🆕 REPLACED: Public Feed instead of Photo Albums
                AuthGuard {
                    FeedView(client: SupabaseManager.shared.client)
                }
                .tabItem {Label("Feed", systemImage: "photo.on.rectangle.angled")}
                .tag(1)
                
                // 🛠️ Quests Tab (existing)
                AuthGuard {
                    QuestView()
                }
                .tabItem {Label("Side Quests", systemImage: "scroll")}
                .tag(2)
                
                // 📷 Camera (existing)
                AuthGuard {
                    CameraButtonView()
                        .environmentObject(galleryViewModel)
                        .environmentObject(notificationManager)
                }
                .environmentObject(session)
                .tabItem { Label("Camera", systemImage: "camera") }
                .tag(3)
                
                // 👤 Character (existing)
                AuthGuard {
                    CharacterProfileView()
                }
                .tabItem {
                    Label("Character", systemImage: "person.crop.circle")
                }
                .tag(4)
                
            }
            .environmentObject(session)
            .accentColor(accentColorName.toColor())
            .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }
}
