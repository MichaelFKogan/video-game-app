import SwiftUI

struct DailyEntryDetailView: View {
    let entry: DailyEntry
    
    let spacing: CGFloat = 2
    
    var itemWidth: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        return (screenWidth - 2 * spacing) / 2
    }
    
//    var itemWidth: CGFloat {
//        let screenWidth = UIScreen.main.bounds.width
//        let horizontalPadding: CGFloat = 16   // or whatever matches your .padding(.horizontal)
//        let totalSpacing = spacing + (horizontalPadding * 2)
//        return (screenWidth - totalSpacing) / 2
//    }

    
    let gridColumns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]
    
    let dummyImageURLs: [String] = [
        "https://im.runware.ai/image/ii/f0ef5cc6-7a8c-4c3b-ad2b-9880e3775acb.JPEG?_gl=1*1s6r7ft*_gcl_au*MTg3MTQzMjg3My4xNzU1MzYwNDA3",
        "https://im.runware.ai/image/ws/2/ii/a955ce72-71c2-40c1-b707-d89f8fe98416.jpg",
        "https://im.runware.ai/image/ii/330aea67-b766-4cb6-a8a3-3f8d7e6fcc2c.JPEG?_gl=1*1s6r7ft*_gcl_au*MTg3MTQzMjg3My4xNzU1MzYwNDA3",
        "https://im.runware.ai/image/ii/8d6e72ea-0ac1-41a6-a4a1-369536344ce7.JPEG?_gl=1*1ynnsuc*_gcl_au*MTg3MTQzMjg3My4xNzU1MzYwNDA3"
    ]
    
    var allImages: [String] {
        entry.imageURLs.isEmpty ? dummyImageURLs : entry.imageURLs + dummyImageURLs
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 2) {
                
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
                
                // Main photo
                if let firstURL = allImages.first, let url = URL(string: firstURL) {
                    NavigationLink(destination: FullPhotoDetailView(entry: entry, imageURL: firstURL)) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(height: 400)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 400)
                                    .clipped()
//                                    .cornerRadius(2)
                                    .shadow(radius: 4)
//                                    .padding(.horizontal)
                            case .failure(_):
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 400)
                                    .overlay(Text("Failed to load image"))
//                                    .cornerRadius(2)
//                                    .padding(.horizontal)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Image Grid for additional images
                LazyVGrid(columns: gridColumns, spacing: spacing) {
                    ForEach(allImages.dropFirst(), id: \.self) { urlString in
                        if let url = URL(string: urlString) {
                            NavigationLink {
                                FullscreenImageView(urlString: urlString)
                            } label: {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .empty:
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: itemWidth, height: 250)
//                                            .cornerRadius(6)
                                            .overlay(ProgressView())
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: itemWidth, height: 250)
                                            .clipped()
//                                            .cornerRadius(6)
//                                            .overlay(
//                                                VStack {
//                                                    if index < sampleActivities.count {
//                                                        let activity = sampleActivities[index]
//                                                        HStack {
//                                                            Spacer()
//                                                            Text("\(activity.emoji)+\(activity.xp)")
//                                                                .opacity(0.9)
//                                                        }
//                                                        Spacer()
//                                                    }
//                                                }
//                                            )
                                    case .failure:
                                        Rectangle()
                                            .fill(Color.red.opacity(0.3))
                                            .frame(width: itemWidth, height: 250)
//                                            .cornerRadius(6)
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                            }
                        }
                    }
                }
//                .padding(.horizontal)

                
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



struct FullscreenImageView: View {
    let urlString: String
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .scaleEffect(1.2)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .ignoresSafeArea()
                    case .failure(_):
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                            Text("Failed to load")
                        }
                        .foregroundColor(.white.opacity(0.8))
                    @unknown default:
                        EmptyView()
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
