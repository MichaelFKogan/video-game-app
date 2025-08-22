//
//  Untitled.swift
//  Video Game App
//
//  Created by Mike K on 8/16/25.
//

import SwiftUI

struct QuestDetailView: View {
    let quest: Quest
    
    @State private var steps: [String] = ["Step 1", "Step 2", "Step 3"]
    @State private var photos: [String] = [] // URLs or local image paths
    @State private var progress: Double = 0.3
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // Header Image
                if let url = URL(string: quest.imageURL) {
                    AsyncImage(url: url) { image in
                        image.resizable()
                             .scaledToFill()
                             .frame(height: 250)
                             .clipped()
                    } placeholder: {
                        ProgressView()
                            .frame(height: 250)
                    }
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                
                // Quest Title
                Text(quest.title)
                    .font(.largeTitle)
                    .bold()
                    .padding(.horizontal)
                
                // Progress Bar
                VStack(alignment: .leading) {
                    Text("Progress")
                        .font(.headline)
                    ProgressView(value: progress)
                        .padding(.horizontal)
                }
                
                // Quest Steps
                VStack(alignment: .leading, spacing: 10) {
                    Text("Steps")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        HStack {
                            Image(systemName: "circle") // Change to "checkmark.circle" if completed
                            Text(step)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .onTapGesture {
                            // toggle completion or edit step
                        }
                    }
                }
                
                // Photo Journal
                VStack(alignment: .leading, spacing: 10) {
                    Text("Photo Journal")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(photos, id: \.self) { photo in
                                if let url = URL(string: photo) {
                                    AsyncImage(url: url) { image in
                                        image.resizable()
                                             .scaledToFill()
                                             .frame(width: 120, height: 120)
                                             .clipped()
                                             .cornerRadius(10)
                                    } placeholder: {
                                        ProgressView()
                                            .frame(width: 120, height: 120)
                                    }
                                }
                            }
                            // Add photo button
                            Button(action: {
                                // Add photo logic
                            }) {
                                ZStack {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 120, height: 120)
                                        .cornerRadius(10)
                                    Image(systemName: "plus")
                                        .font(.largeTitle)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
            }
            .padding(.vertical)
        }
        .navigationTitle("Quest Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}
