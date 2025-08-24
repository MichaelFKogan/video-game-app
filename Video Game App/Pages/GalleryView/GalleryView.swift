import SwiftUI

struct GalleryView: View {
    @EnvironmentObject var viewModel: GalleryViewModel
    @AppStorage("accentColorName") private var accentColorName: String = "blue"
    
//    @AppStorage("galleryImages") private var savedGalleryImagesData: Data = Data()
//    @StateObject private var viewModel = GalleryViewModel()
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 3)
    let spacing: CGFloat = 2
    
    @State private var isGridView: Bool = true // Track current view
    
    @State private var showCameraSheet = false
    @State private var navigateToProfile = false
    
    @State private var galleryImages: [String] = []

//    func loadGalleryImages() {
//        if let decoded = try? JSONDecoder().decode([String].self, from: savedGalleryImagesData), !decoded.isEmpty {
//            galleryImages = decoded
//        } else {
//            // fallback to default images
//            galleryImages = imageURLs
//        }
//    }
//
//    func saveGalleryImages() {
//        if let encoded = try? JSONEncoder().encode(galleryImages) {
//            savedGalleryImagesData = encoded
//        }
//    }

//    func addNewImage(_ url: String) {
//        galleryImages.insert(url, at: 0)   // Add at the beginning
//        saveGalleryImages()                // Persist the updated array
//    }
    
//    // Dummy image URLs
//    let imageURLs: [String] = [
//        "https://im.runware.ai/image/ws/2/ii/9139c938-47a8-4957-bffd-b9bf0289279c.jpg"
//    ]
    
    struct GalleryImage: Identifiable, Hashable {
        let id: UUID
        let url: String
    }
    
    let gridColumns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]
    
    var itemWidth: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        return (screenWidth - 2 * spacing) / 3
    }
    
//    @State private var useGhibli = false // <- Toggle state
    
    var displayedImages: [String] {
        galleryImages
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { proxy in
                // We’ll give the grid 2pt padding on each side and subtract it from the math.
                let columns = gridColumns
                let horizontalOuterPadding: CGFloat = spacing // matches .padding(.horizontal, spacing)
                let totalInteritemSpacing = spacing * CGFloat(columns.count - 1)
                let contentWidth = proxy.size.width - (horizontalOuterPadding * 2)
                let itemWidth = (contentWidth - totalInteritemSpacing) / CGFloat(columns.count)
                
                ZStack{
                    
                    ScrollView {
                        
                        HStack{

                            Text("📖 Storyline")
                                .font(.largeTitle)
                                .fontWeight(.bold)

                            Spacer()

                            // Grid view button
                            Button(action: {
                                isGridView = true
                            }) {
                                Image(systemName: "square.grid.2x2")
                                    .font(.title2)
                                    .foregroundColor(isGridView ? .accentColor : .secondary)
                            }

                            // List view button
                            Button(action: {
                                isGridView = false
                            }) {
                                Image(systemName: "rectangle.stack")
                                    .font(.title2)
                                    .foregroundColor(!isGridView ? .accentColor : .secondary)
                            }

                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .zIndex(1)
                        
                        VStack{
                            Text(buildInstructionText(accentColorName: accentColorName))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .onTapGesture {
                                    navigateToProfile = true
                                }
                        }
                        .padding(.bottom, 20)
                        .padding(.horizontal)
                        
                        // Character Stats - Navigate To Character Page - Hidden NavigationLink
                        NavigationLink(
                            destination: CharacterProfileView(),
                            isActive: $navigateToProfile,
                            label: { EmptyView() }
                        )
                        
                        if isGridView {
                            LazyVGrid(columns: columns, spacing: spacing) {
                                // Show loading placeholders first
                                ForEach(viewModel.loadingPhotos, id: \.self) { _ in
                                    LoadingPhotoPlaceholder(width: itemWidth, height: 200)
                                }

                                // Show actual images with titles and descriptions
                                ForEach(Array(viewModel.galleryImages.enumerated()), id: \.element) { index, url in
                                    let photo = viewModel.getPhoto(for: url)
                                    NavigationLink(destination: GalleryDetailView(
                                        imageURL: url,
                                        photo: photo
                                    )
                                    .environmentObject(viewModel)) {
                                        VStack(alignment: .leading, spacing: 4) {
//                                            // Title above image (only show if exists)
//                                            if let title = photo?.title, !title.isEmpty {
//                                                Text(title)
//                                                    .font(.caption)
//                                                    .fontWeight(.medium)
//                                                    .foregroundColor(.primary)
//                                                    .lineLimit(2)
//                                                    .multilineTextAlignment(.leading)
//                                            }
                                            
                                            // Image
                                            CachedAsyncImage(url: URL(string: url)) { image in
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: itemWidth, height: 200)
                                                    .clipped()
                                            } placeholder: {
                                                ProgressView()
                                                    .frame(width: itemWidth, height: 200)
                                            }
                                            
//                                            // Description below image (only show if exists)
//                                            if let description = photo?.description, !description.isEmpty {
//                                                Text(description)
//                                                    .font(.caption2)
//                                                    .foregroundColor(.secondary)
//                                                    .lineLimit(2)
//                                                    .multilineTextAlignment(.leading)
//                                            }
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            // Use horizontal padding equal to `spacing` so the math lines up
                            .padding(.horizontal, horizontalOuterPadding)
                            .padding(.bottom) // optional
                        } else {
                            LazyVStack(spacing: spacing) {
                                // Show loading placeholders first
                                ForEach(viewModel.loadingPhotos, id: \.self) { _ in
                                    LoadingPhotoPlaceholder(width: contentWidth, height: 200)
                                }

                                // Show actual images styled like QuestView cards
                                ForEach(Array(viewModel.galleryImages.enumerated()), id: \.element) { index, url in
                                    let photo = viewModel.getPhoto(for: url)
                                    NavigationLink(destination: GalleryDetailView(
                                        imageURL: url,
                                        photo: photo
                                    )
                                    .environmentObject(viewModel)) {
                                        VStack(alignment: .leading) {
                                            // Real title from photo - ABOVE the image
                                            if let title = photo?.title, !title.isEmpty {
                                                Text(title)
                                                    .font(.headline)
                                                    .padding(.leading)
                                            }

                                            // Image with XP overlay
                                            ZStack(alignment: .topTrailing) {
                                                CachedAsyncImage(url: URL(string: url)) { image in
                                                    image
                                                        .resizable()
                                                        .scaledToFill()
                                                        .frame(height: 250)
                                                        .frame(maxWidth: .infinity)
                                                        .clipped()
                                                } placeholder: {
                                                    ProgressView()
                                                        .frame(height: 250)
                                                        .frame(maxWidth: .infinity)
                                                }

                                                // XP overlay (using a simple XP value for now)
                                                HStack(spacing: 4) {
                                                    Image(systemName: "star.fill")
                                                        .foregroundColor(.yellow).opacity(0.8)
                                                    Text("\(10 + (index % 20)) XP")
                                                        .font(.caption)
                                                        .bold()
                                                        .foregroundColor(.white).opacity(0.8)
                                                }
                                                .padding(6)
                                                .background(Color.black.opacity(0.7))
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                                .padding(8)
                                            }
                                            .padding(.horizontal)

                                            // Real description from photo - BELOW the image
                                            if let description = photo?.description, !description.isEmpty {
                                                Text(description)
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                                    .multilineTextAlignment(.leading)
                                                    .padding([.horizontal, .top, .bottom])
                                            }
                                        }
                                        .padding(.top, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(Color(.systemBackground))
                                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                                        )
                                        .padding(.horizontal)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, horizontalOuterPadding)
                            .padding(.bottom) // optional
                        }
                        
                        
                        //                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 4) {
                        //                        ForEach(viewModel.galleryImages, id: \.self) { url in
                        //                            AsyncImage(url: URL(string: url)) { image in
                        //                                image.resizable().scaledToFit()
                        //                            } placeholder: {
                        //                                ProgressView()
                        //                            }
                        //                        }
                        //                    }
                        //
                        //                    LazyVGrid(columns: gridColumns, spacing: spacing) {
                        //                        ForEach(displayedImages.indices, id: \.self) { index in
                        //                            let urlString = displayedImages[index]
                        //                            if let url = URL(string: urlString) {
                        //                                NavigationLink {
                        //                                    FullscreenImageView(urlString: urlString)
                        //                                } label: {
                        //                                    AsyncImage(url: url) { phase in
                        //                                        switch phase {
                        //                                        case .empty:
                        //                                            Rectangle()
                        //                                                .fill(Color.gray.opacity(0.3))
                        //                                                .frame(width: itemWidth, height: 200)
                        //                                                .overlay(ProgressView())
                        //                                        case .success(let image):
                        //                                            image
                        //                                                .resizable()
                        //                                                .scaledToFill()
                        //                                                .frame(width: itemWidth, height: 200)
                        //                                                .clipped()
                        //                                                .overlay(
                        //                                                    VStack {
                        //                                                        if index < sampleActivities.count {
                        //                                                            let activity = sampleActivities[index]
                        //                                                            HStack {
                        //                                                                Spacer()
                        //                                                                Text("\(activity.emoji)+\(activity.xp)").opacity(0.9)
                        //                                                                    .font(.caption2).bold()
                        //                                                                    .foregroundColor(.white)
                        //                                                                    .padding(6)
                        //                                                                    .background(Color.black.opacity(0.6))
                        //                                                                    .cornerRadius(6)
                        //                                                            }
                        //                                                            .padding(4)
                        //                                                            Spacer()
                        //                                                            LinearGradient(
                        //                                                                gradient: Gradient(colors: [Color.black.opacity(1), Color.clear]),
                        //                                                                startPoint: .bottom,
                        //                                                                endPoint: .top
                        //                                                            )
                        //                                                            .frame(height: 40)
                        //
                        //                                                            .overlay(
                        //                                                                Text(activity.title)
                        //                                                                    .font(.caption).bold()
                        //                                                                    .foregroundColor(.white)
                        //                                                                    .lineLimit(2)
                        //                                                                    .padding(4),
                        //                                                                alignment: .bottomLeading
                        //                                                            )
                        //                                                        }
                        //                                                    }
                        //                                                )
                        //                                        case .failure(_):
                        //                                            Rectangle()
                        //                                                .fill(Color.red.opacity(0.3))
                        //                                                .frame(width: itemWidth, height: 200)
                        //                                                .overlay(Text("Failed To Load"))
                        //                                        @unknown default:
                        //                                            EmptyView()
                        //                                        }
                        //                                    }
                        //                                }
                        //                                .buttonStyle(PlainButtonStyle())
                        //                            }
                        //                        }
                        //                    }
                        //                    .padding(.bottom, 200)
                        
                        
                        
                        
                    }
                    
                }
                .onAppear {
                    viewModel.preloadImages()
                }
                // ✅ Attach the sheet here
                .sheet(isPresented: $showCameraSheet) {
                    NavigationView {
                        CameraButtonView()
                    }
                }
            }
        }
    }
}

func buildInstructionText(accentColorName: String) -> AttributedString {
    var attributed = AttributedString("Document your life through photos. Record anything, from the mundane to the interesting. Earn points for each photo you add and increase your ")
    var linkPart = AttributedString("character stats.")
    linkPart.foregroundColor = accentColorName.toColor()
//    linkPart.underlineStyle = .single
    // Append the tappable part
    attributed.append(linkPart)
    return attributed
}
