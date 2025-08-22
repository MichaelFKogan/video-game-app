import SwiftUI

struct DailyEntry: Identifiable {
    let id = UUID()
    let date: Date
    let title: String
    let description: String
    let imageURLs: [String] // Up to 5 photos per day
}

struct DailyEntries: View {
    
    // Dummy daily entries
    let entries: [DailyEntry] = [
        DailyEntry(
            date: Date(),
            title: "Morning Stretch",
            description: "Perform your heroic morning stretches to awaken your muscles and mind.",
            imageURLs: [
                "https://im.runware.ai/image/ws/2/ii/a955ce72-71c2-40c1-b707-d89f8fe98416.jpg"
            ]
        ),
        DailyEntry(
            date: Date(),
            title: "Breakfast Quest",
            description: "Prepare and consume a nourishing breakfast potion to gain energy for today's adventures.",
            imageURLs: [
                "https://im.runware.ai/image/ii/8d6e72ea-0ac1-41a6-a4a1-369536344ce7.JPEG?_gl=1*1ynnsuc*_gcl_au*MTg3MTQzMjg3My4xNzU1MzYwNDA3"
            ]
        ),
        DailyEntry(
            date: Date(),
            title: "Evening Journaling",
            description: "Record your achievements, failures, and treasures discovered throughout the day.",
            imageURLs: [] // No photos
        )
    ]
    
    // Optional XP or points for each daily entry
    let points: [Int] = [20, 50, 10]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    
                    HStack {
                        Text("📓 Daily Journal")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Spacer()
                    }
                    .padding()
                    
                    ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                        NavigationLink(destination: DailyEntryDetailView(entry: entry)) {
                            VStack(alignment: .leading, spacing: 8) {
                                
                                // Date
                                Text(entry.date, style: .date)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.leading)
                                
                                // Title
                                Text(entry.title)
                                    .font(.headline)
                                    .padding(.leading)
                                
                                // Optional Cover Image
                                if let firstURL = entry.imageURLs.first, let url = URL(string: firstURL) {
                                    ZStack(alignment: .topTrailing) {
                                        AsyncImage(url: url) { phase in
                                            switch phase {
                                            case .empty:
                                                ProgressView()
                                                    .frame(height: 250)
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(height: 250)
                                                    .clipped()
                                            case .failure(_):
                                                Rectangle()
                                                    .fill(Color.gray.opacity(0.3))
                                                    .frame(height: 250)
                                                    .overlay(Text("Failed to load"))
                                            @unknown default:
                                                EmptyView()
                                            }
                                        }
                                        .cornerRadius(10)
                                        
                                        // Points Badge
                                        if points.indices.contains(index) {
                                            HStack(spacing: 4) {
                                                Image(systemName: "star.fill")
                                                    .foregroundColor(.yellow).opacity(0.8)
                                                Text("\(points[index]) XP")
                                                    .font(.caption)
                                                    .bold()
                                                    .foregroundColor(.white).opacity(0.8)
                                            }
                                            .padding(6)
                                            .background(Color.black.opacity(0.7))
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .padding(8)
                                        }
                                    }
                                    .padding(.horizontal)
                                } else {
                                    // Placeholder for days with no photos
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.1))
                                        .frame(height: 250)
                                        .overlay(Text("No photos yet").foregroundColor(.secondary))
                                        .cornerRadius(10)
                                        .padding(.horizontal)
                                }
                                
                                // Description
                                Text(entry.description)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.leading)
                                    .padding([.horizontal, .bottom])
                                
//                                // Photo count
//                                if !entry.imageURLs.isEmpty {
//                                    Text("\(entry.imageURLs.count)/5 photos used today")
//                                        .font(.caption)
//                                        .foregroundColor(.secondary)
//                                        .padding(.leading)
//                                }
                                
                            }
                            .padding(.top, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                            )
                            .padding(.horizontal)
                        }
                    }
                }
            }
        }
    }
}
