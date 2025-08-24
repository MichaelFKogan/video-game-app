import SwiftUI

struct GalleryDetailView: View {
    let imageURL: String
    let photo: Photo?
    @AppStorage("accentColorName") private var accentColorName: String = "blue"
    @EnvironmentObject var viewModel: GalleryViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showingDeleteAlert = false
    @State private var isDeleting = false
    
    // Real data from photo object
    private var displayTitle: String {
        if let photo = photo, let title = photo.title, !title.isEmpty {
            return title
        }
        return "Untitled Adventure"
    }
    
    private var displayDescription: String {
        if let photo = photo, let description = photo.description, !description.isEmpty {
            return description
        }
        return ""
    }
    
    private var mockXP: Int {
        Int.random(in: 10...50)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Full-sized image
                CachedAsyncImage(url: URL(string: imageURL)) { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(12)
                        .shadow(radius: 8)
                } placeholder: {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 400)
                        .background(Color.gray.opacity(0.1))
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 16) {
                    // Title and XP
                    HStack {
                        Text(displayTitle)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        // XP Badge
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text("\(mockXP) XP")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(accentColorName.toColor())
                        .cornerRadius(8)
                    }
                    
                    // Date
                    if let photo = photo {
                        Text(photo.created_at, style: .date)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text(Date(), style: .date)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Description (only show if it exists)
                    if !displayDescription.isEmpty {
                        Text(displayDescription)
                            .font(.body)
                            .foregroundColor(.primary)
                            .lineLimit(nil)
                    }
                    
                    // Stats Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Adventure Stats")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            StatCard(title: "Location", value: "California", icon: "location.fill", color: .blue)
                            StatCard(title: "Weather", value: "Sunny", icon: "sun.max.fill", color: .orange)
                            StatCard(title: "Mood", value: "Happy", icon: "face.smiling", color: .green)
                            StatCard(title: "Energy", value: "High", icon: "bolt.fill", color: .yellow)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Action Buttons
                    HStack(spacing: 12) {
                        Button(action: {
                            // Share functionality
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray5))
                            .foregroundColor(.primary)
                            .cornerRadius(8)
                        }
                        
                        Button(action: {
                            // Edit functionality
                        }) {
                            HStack {
                                Image(systemName: "pencil")
                                Text("Edit")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(accentColorName.toColor())
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                    }
                    
                    // Delete Button
                    if photo != nil {
                        Button(action: {
                            showingDeleteAlert = true
                        }) {
                            HStack {
                                if isDeleting {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .foregroundColor(.white)
                                } else {
                                    Image(systemName: "trash")
                                }
                                Text(isDeleting ? "Deleting..." : "Delete")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .disabled(isDeleting)
                    }
                }
                .padding(.horizontal)
                
                Spacer(minLength: 20)
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Adventure Detail")
        .alert("Delete Photo", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deletePhoto()
            }
        } message: {
            Text("Are you sure you want to delete this photo? This action cannot be undone.")
        }
    }
    
    private func deletePhoto() {
        guard let photo = photo else { return }
        
        isDeleting = true
        
        Task {
            await viewModel.deletePhoto(photoId: photo.id)
            
            await MainActor.run {
                isDeleting = false
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    NavigationView {
        GalleryDetailView(
            imageURL: "https://im.runware.ai/image/ws/2/ii/9139c938-47a8-4957-bffd-b9bf0289279c.jpg",
            photo: nil
        )
    }
}
