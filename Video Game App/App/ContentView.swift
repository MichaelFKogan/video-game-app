import SwiftUI

struct ContentView: View {
    
    @StateObject private var session = SessionStore()
    @StateObject private var galleryViewModel = GalleryViewModel(client: supabase)
    @StateObject private var notificationManager = GlobalNotificationManager()

    @AppStorage("isDarkMode") private var isDarkMode = true
    @AppStorage("accentColorName") private var accentColorName: String = "blue"
    @State private var selectedTab = 0 // Start with Home tab
    @State private var showCamera = false
    
    
    var body: some View {

        ZStack {
            // Global notification overlay
            GlobalNotificationView(notificationManager: notificationManager)
            
            TabView(selection: $selectedTab) {
                
//            // 🏠 Home
//                VStack {
//                    Text("Home")
//                        .font(.largeTitle)
//                }
//                .tabItem {
//                    Label("Home", systemImage: "house") // fire or food icon vibes
//                }
//                .tag(0)
//                
            // 🌃 Gallery / Home Tab
//                Storyline()
//                VStack {
//                    Text("Storyline")
//                    .font(.largeTitle)
//                }
//                    .tabItem {Label("Storyline", systemImage: "square.grid.2x2")}
//                    .tag(1)
                
            // 📓 Daily Entries
                AuthGuard {
//                    DailyEntries()
                    GalleryView()
                        .environmentObject(galleryViewModel)
                }
                    .tabItem {Label("Storyline", systemImage: "book.closed")}
                    .tag(0)
                
            // 🛠️ Quests Tab
                AuthGuard {
                    QuestView()
                }
                    .tabItem {Label("Side Quests", systemImage: "scroll")}
                    .tag(1)
                
            // 📷 Camera
                AuthGuard {
                    CameraButtonView()
                        .environmentObject(galleryViewModel)
                        .environmentObject(notificationManager)
                }
                .environmentObject(session)
                    .tabItem { Label("Camera", systemImage: "camera") }
                    .tag(2)
                
            // 👤 Character
                AuthGuard {
                    CharacterProfileView()
                }
                    .tabItem {
                        Label("Character", systemImage: "person.crop.circle")
                    }
                    .tag(3)
                
            // ⚙️ Settings
                    Settings()
                
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
                    .tag(4)
                
            }
            .environmentObject(session)
            .accentColor(accentColorName.toColor())
            .preferredColorScheme(isDarkMode ? .dark : .light)
            
        // 📸 Floating Camera Button
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
            
        }
    }
}

