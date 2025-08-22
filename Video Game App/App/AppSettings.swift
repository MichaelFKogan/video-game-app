//
//  AppSettings.swift
//  Video Game App
//
//  Created by Mike K on 8/21/25.
//

// AppSettings.swift
import SwiftUI

final class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    @AppStorage("accentColorName") var accentColorName: String = "blue"
    @AppStorage("isDarkMode") var isDarkMode: Bool = true
    
    private init() {} // Singleton pattern
}
