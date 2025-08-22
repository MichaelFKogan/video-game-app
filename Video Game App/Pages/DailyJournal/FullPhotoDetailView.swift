//
//  FullPhotoDetailView.swift
//  Video Game App
//
//  Created by Mike K on 8/17/25.
//

import SwiftUI

// MARK: - Full Photo Detail View
struct FullPhotoDetailView: View {
    let entry: DailyEntry
    let imageURL: String
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Date
                Text(entry.date, style: .date)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                // Title
                Text(entry.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                // Full-sized photo
                if let url = URL(string: imageURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(maxWidth: .infinity, minHeight: 300)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(12)
                                .shadow(radius: 4)
                                .padding(.horizontal)
                        case .failure(_):
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 300)
                                .overlay(Text("Failed to load image"))
                                .cornerRadius(12)
                                .padding(.horizontal)
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
                
                // Description
                Text(entry.description)
                    .font(.body)
                    .foregroundColor(.primary)
                    .padding(.horizontal)
                
                Spacer(minLength: 20)
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
