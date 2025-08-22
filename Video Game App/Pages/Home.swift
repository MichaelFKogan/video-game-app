import SwiftUI

struct Home: View {
    
    
    // Dummy image URLs
    let imageURLs: [String] = [
        "https://im.runware.ai/image/ii/f0ef5cc6-7a8c-4c3b-ad2b-9880e3775acb.JPEG?_gl=1*1s6r7ft*_gcl_au*MTg3MTQzMjg3My4xNzU1MzYwNDA3LjE2OTk0NDA3MDQuMTc1NTM4MDY4My4xNzU1MzgwNjgz",
        "https://im.runware.ai/image/ii/2cd42f14-1535-458c-9436-26012fa088e4.JPEG?_gl=1*1s6r7ft*_gcl_au*MTg3MTQzMjg3My4xNzU1MzYwNDA3LjE2OTk0NDA3MDQuMTc1NTM4MDY4My4xNzU1MzgwNjgz",
        "https://im.runware.ai/image/ii/330aea67-b766-4cb6-a8a3-3f8d7e6fcc2c.JPEG?_gl=1*1s6r7ft*_gcl_au*MTg3MTQzMjg3My4xNzU1MzYwNDA3LjE2OTk0NDA3MDQuMTc1NTM4MDY4My4xNzU1MzgwNjgz",
        "https://im.runware.ai/image/ii/8d6e72ea-0ac1-41a6-a4a1-369536344ce7.JPEG?_gl=1*1ynnsuc*_gcl_au*MTg3MTQzMjg3My4xNzU1MzYwNDA3",
        "https://im.runware.ai/image/ws/2/ii/a955ce72-71c2-40c1-b707-d89f8fe98416.jpg",
        "https://im.runware.ai/image/ws/2/ii/535420ed-cb46-48a1-a0b7-0024154b8620.jpg",
        "https://im.runware.ai/image/ws/2/ii/6e114654-74ed-4b52-9573-ff5e2cb04c9d.jpg",
        "https://im.runware.ai/image/ws/2/ii/9139c938-47a8-4957-bffd-b9bf0289279c.jpg",
        
        "https://im.runware.ai/image/ii/f0ef5cc6-7a8c-4c3b-ad2b-9880e3775acb.JPEG?_gl=1*1s6r7ft*_gcl_au*MTg3MTQzMjg3My4xNzU1MzYwNDA3LjE2OTk0NDA3MDQuMTc1NTM4MDY4My4xNzU1MzgwNjgz",
        "https://im.runware.ai/image/ii/2cd42f14-1535-458c-9436-26012fa088e4.JPEG?_gl=1*1s6r7ft*_gcl_au*MTg3MTQzMjg3My4xNzU1MzYwNDA3LjE2OTk0NDA3MDQuMTc1NTM4MDY4My4xNzU1MzgwNjgz",
        "https://im.runware.ai/image/ii/330aea67-b766-4cb6-a8a3-3f8d7e6fcc2c.JPEG?_gl=1*1s6r7ft*_gcl_au*MTg3MTQzMjg3My4xNzU1MzYwNDA3LjE2OTk0NDA3MDQuMTc1NTM4MDY4My4xNzU1MzgwNjgz",
        "https://im.runware.ai/image/ii/8d6e72ea-0ac1-41a6-a4a1-369536344ce7.JPEG?_gl=1*1ynnsuc*_gcl_au*MTg3MTQzMjg3My4xNzU1MzYwNDA3",
        "https://im.runware.ai/image/ws/2/ii/a955ce72-71c2-40c1-b707-d89f8fe98416.jpg",
        "https://im.runware.ai/image/ws/2/ii/535420ed-cb46-48a1-a0b7-0024154b8620.jpg",
        "https://im.runware.ai/image/ws/2/ii/6e114654-74ed-4b52-9573-ff5e2cb04c9d.jpg",
        "https://im.runware.ai/image/ws/2/ii/9139c938-47a8-4957-bffd-b9bf0289279c.jpg"
    ]
    
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(Array(imageURLs.enumerated()), id: \.offset) { index, urlString in
                        VStack(alignment: .leading) {
                            // Username
                            Text("User\(index + 1)")
                                .font(.headline)
                                .padding(.leading)
                            
                            // Image
                            if let url = URL(string: urlString) {
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
                                .padding(.horizontal)
                            }
                            
                            // Likes / Stats
                            HStack {
                                Image(systemName: "heart")
                                Text("\(Int.random(in: 1...100)) likes")
                                Spacer()
                                Image(systemName: "bubble.right")
                                Text("\(Int.random(in: 0...50)) comments")
                            }
                            .font(.subheadline)
                            .padding(.horizontal)
                        }
                        .padding(.bottom, 10)
                    }
                }
            }
        }
    }
}

