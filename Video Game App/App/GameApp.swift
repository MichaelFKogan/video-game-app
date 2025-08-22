//
//  GameApp.swift
//  Video Game App
//
//  Created by Mike K on 8/15/25.
//

import SwiftUI

@main
struct GameApp: App {
//    @StateObject private var sessionStore = SessionStore()
//    @AppStorage("isDarkMode") private var isDarkMode = true
//    @AppStorage("accentColorName") private var accentColorName: String = "blue"

    var body: some Scene {
        WindowGroup {
            ContentView()
//            GalleryView()
//                .environmentObject(sessionStore)
//                .accentColor(accentColorName.toColor())
//                .preferredColorScheme(isDarkMode ? .dark : .light) // apply dark/light mode
        }
    }
}
