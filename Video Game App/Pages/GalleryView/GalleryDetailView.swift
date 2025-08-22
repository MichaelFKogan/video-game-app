import SwiftUI

struct GalleryDetailView: View {
    let imageURL: String
    let photo: Photo?
    @AppStorage("accentColorName") private var accentColorName: String = "blue"
    
    // Mock data for demo - in real app this would come from the photo object
    private var mockTitle: String {
        let titles = [
            "Morning Coffee Quest",
            "City Exploration Adventure",
            "Work From Home Mission",
            "Grocery Shopping Run",
            "Evening Walk Discovery",
            "Lunch Break Escape",
            "Weekend Warrior Challenge",
            "Daily Commute Journey"
        ]
        return titles.randomElement() ?? "Life Adventure"
    }
    
    private var mockDescription: String {
        let descriptions = [
            "Started the day with a perfect cup of coffee and some quiet reflection.",
            "Explored the bustling city streets and discovered hidden gems around every corner.",
            "Another productive day working from the comfort of home office.",
            "Successfully navigated the grocery store maze and emerged victorious with supplies.",
            "Took an evening stroll and found peace in the simple moments of life.",
            "Escaped the daily grind for a quick lunch break and some fresh air.",
            "Embraced the weekend warrior spirit with some outdoor activities.",
            "Made the daily commute feel like an adventure through the urban landscape."
        ]
        return descriptions.randomElement() ?? "Another day in the adventure of life."
    }
    
    private var mockXP: Int {
        Int.random(in: 10...50)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Full-sized image
                AsyncImage(url: URL(string: imageURL)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 400)
                            .background(Color.gray.opacity(0.1))
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(12)
                            .shadow(radius: 8)
                    case .failure(_):
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 400)
                            .overlay(
                                VStack {
                                    Image(systemName: "exclamationmark.triangle")
                                        .font(.largeTitle)
                                        .foregroundColor(.gray)
                                    Text("Failed to load image")
                                        .foregroundColor(.gray)
                                }
                            )
                            .cornerRadius(12)
                    @unknown default:
                        EmptyView()
                    }
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 16) {
                    // Title and XP
                    HStack {
                        Text(mockTitle)
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
                    
                    // Description
                    Text(mockDescription)
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineLimit(nil)
                    
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
                }
                .padding(.horizontal)
                
                Spacer(minLength: 20)
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Adventure Detail")
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
