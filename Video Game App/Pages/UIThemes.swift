//
//  UIThemes.swift
//  Video Game App
//
//  Created by Mike K on 8/16/25.
//

import SwiftUI

struct UIThemes: View {
    var body: some View {
        NavigationStack {
            List {
                // Example: a dark theme preview
                Section("Themes") {
                    Text("Dark Theme Example")
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .navigationTitle("UI Themes")
        }
    }
}
