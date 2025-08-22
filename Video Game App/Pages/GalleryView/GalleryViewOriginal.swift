//import SwiftUI
//
//struct GalleryView: View {
//    @AppStorage("galleryImages") private var savedGalleryImagesData: Data = Data()
//    @StateObject private var viewModel = GalleryViewModel()
//    
//    let spacing: CGFloat = 2
//    @State private var isGridView: Bool = true // Track current view
//    
//    @State private var showCameraSheet = false
//    @State private var navigateToProfile = false
//    
//    @State private var galleryImages: [String] = []
//
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
//
//    func addNewImage(_ url: String) {
//        galleryImages.insert(url, at: 0)   // Add at the beginning
//        saveGalleryImages()                // Persist the updated array
//    }
//    
//    // Dummy image URLs
//    let imageURLs: [String] = [
//        "https://im.runware.ai/image/ii/f0ef5cc6-7a8c-4c3b-ad2b-9880e3775acb.JPEG?_gl=1*1s6r7ft*_gcl_au*MTg3MTQzMjg3My4xNzU1MzYwNDA3LjE2OTk0NDA3MDQuMTc1NTM4MDY4My4xNzU1MzgwNjgz",
//        "https://im.runware.ai/image/ii/2cd42f14-1535-458c-9436-26012fa088e4.JPEG?_gl=1*1s6r7ft*_gcl_au*MTg3MTQzMjg3My4xNzU1MzYwNDA3LjE2OTk0NDA3MDQuMTc1NTM4MDY4My4xNzU1MzgwNjgz",
//        "https://im.runware.ai/image/ii/330aea67-b766-4cb6-a8a3-3f8d7e6fcc2c.JPEG?_gl=1*1s6r7ft*_gcl_au*MTg3MTQzMjg3My4xNzU1MzYwNDA3LjE2OTk0NDA3MDQuMTc1NTM4MDY4My4xNzU1MzgwNjgz",
//        "https://im.runware.ai/image/ii/8d6e72ea-0ac1-41a6-a4a1-369536344ce7.JPEG?_gl=1*1ynnsuc*_gcl_au*MTg3MTQzMjg3My4xNzU1MzYwNDA3",
//        "https://im.runware.ai/image/ws/2/ii/a955ce72-71c2-40c1-b707-d89f8fe98416.jpg",
//        "https://im.runware.ai/image/ws/2/ii/535420ed-cb46-48a1-a0b7-0024154b8620.jpg",
//        "https://im.runware.ai/image/ws/2/ii/6e114654-74ed-4b52-9573-ff5e2cb04c9d.jpg",
//        "https://im.runware.ai/image/ws/2/ii/9139c938-47a8-4957-bffd-b9bf0289279c.jpg",
//        
//        "https://im.runware.ai/image/ii/f0ef5cc6-7a8c-4c3b-ad2b-9880e3775acb.JPEG?_gl=1*1s6r7ft*_gcl_au*MTg3MTQzMjg3My4xNzU1MzYwNDA3LjE2OTk0NDA3MDQuMTc1NTM4MDY4My4xNzU1MzgwNjgz",
//        "https://im.runware.ai/image/ii/2cd42f14-1535-458c-9436-26012fa088e4.JPEG?_gl=1*1s6r7ft*_gcl_au*MTg3MTQzMjg3My4xNzU1MzYwNDA3LjE2OTk0NDA3MDQuMTc1NTM4MDY4My4xNzU1MzgwNjgz",
//        "https://im.runware.ai/image/ii/330aea67-b766-4cb6-a8a3-3f8d7e6fcc2c.JPEG?_gl=1*1s6r7ft*_gcl_au*MTg3MTQzMjg3My4xNzU1MzYwNDA3LjE2OTk0NDA3MDQuMTc1NTM4MDY4My4xNzU1MzgwNjgz",
//        "https://im.runware.ai/image/ii/8d6e72ea-0ac1-41a6-a4a1-369536344ce7.JPEG?_gl=1*1ynnsuc*_gcl_au*MTg3MTQzMjg3My4xNzU1MzYwNDA3",
//        "https://im.runware.ai/image/ws/2/ii/a955ce72-71c2-40c1-b707-d89f8fe98416.jpg",
//        "https://im.runware.ai/image/ws/2/ii/535420ed-cb46-48a1-a0b7-0024154b8620.jpg",
//        "https://im.runware.ai/image/ws/2/ii/6e114654-74ed-4b52-9573-ff5e2cb04c9d.jpg",
//        "https://im.runware.ai/image/ws/2/ii/9139c938-47a8-4957-bffd-b9bf0289279c.jpg"
//    ]
//    
//    // Dummy image URLs
//    let imageURLsGhibli: [String] = [
//        "https://im.runware.ai/image/ii/66255935-1a42-4467-b1b9-0902143d2ce3.JPEG?_gl=1*ctnnsc*_gcl_au*MTg3MTQzMjg3My4xNzU1MzYwNDA3LjE2OTk0NDA3MDQuMTc1NTM4MDY4My4xNzU1MzgwNjgz",
//        "https://im.runware.ai/image/ii/83f6f4d3-4bc3-4a2f-95c9-cc547a149131.JPEG?_gl=1*1s6r7ft*_gcl_au*MTg3MTQzMjg3My4xNzU1MzYwNDA3LjE2OTk0NDA3MDQuMTc1NTM4MDY4My4xNzU1MzgwNjgz",
//        "https://im.runware.ai/image/ii/40619072-75fa-4c63-bb63-a40fb0e5a2e9.JPEG?_gl=1*1s6r7ft*_gcl_au*MTg3MTQzMjg3My4xNzU1MzYwNDA3LjE2OTk0NDA3MDQuMTc1NTM4MDY4My4xNzU1MzgwNjgz",
//        "https://im.runware.ai/image/ii/cf8410b3-8ac0-4f13-a7ca-2f7b4a44f680.JPEG?_gl=1*1ynnsuc*_gcl_au*MTg3MTQzMjg3My4xNzU1MzYwNDA3",
//        "https://im.runware.ai/image/ii/9fc18eeb-9f5c-436d-b00e-b5a87ace2eaa.JPEG?_gl=1*l0ozwt*_gcl_au*MTg3MTQzMjg3My4xNzU1MzYwNDA3",
//        "https://im.runware.ai/image/ws/2/ii/70645e4f-d724-4d43-8597-e29dd14cdb99.jpg",
//        "https://im.runware.ai/image/ws/2/ii/6b69cbd8-d1f3-4b0b-bbe2-d77a658804d8.jpg",
//        "https://im.runware.ai/image/ws/2/ii/6b69cbd8-d1f3-4b0b-bbe2-d77a658804d8.jpg",
//        "https://im.runware.ai/image/ws/2/ii/01996729-9b04-4960-ad1c-e69e52820443.jpg",
//        
//        "https://im.runware.ai/image/ii/66255935-1a42-4467-b1b9-0902143d2ce3.JPEG?_gl=1*ctnnsc*_gcl_au*MTg3MTQzMjg3My4xNzU1MzYwNDA3LjE2OTk0NDA3MDQuMTc1NTM4MDY4My4xNzU1MzgwNjgz",
//        "https://im.runware.ai/image/ii/83f6f4d3-4bc3-4a2f-95c9-cc547a149131.JPEG?_gl=1*1s6r7ft*_gcl_au*MTg3MTQzMjg3My4xNzU1MzYwNDA3LjE2OTk0NDA3MDQuMTc1NTM4MDY4My4xNzU1MzgwNjgz",
//        "https://im.runware.ai/image/ii/40619072-75fa-4c63-bb63-a40fb0e5a2e9.JPEG?_gl=1*1s6r7ft*_gcl_au*MTg3MTQzMjg3My4xNzU1MzYwNDA3LjE2OTk0NDA3MDQuMTc1NTM4MDY4My4xNzU1MzgwNjgz",
//        "https://im.runware.ai/image/ii/cf8410b3-8ac0-4f13-a7ca-2f7b4a44f680.JPEG?_gl=1*1ynnsuc*_gcl_au*MTg3MTQzMjg3My4xNzU1MzYwNDA3",
//        "https://im.runware.ai/image/ii/9fc18eeb-9f5c-436d-b00e-b5a87ace2eaa.JPEG?_gl=1*l0ozwt*_gcl_au*MTg3MTQzMjg3My4xNzU1MzYwNDA3",
//        "https://im.runware.ai/image/ws/2/ii/70645e4f-d724-4d43-8597-e29dd14cdb99.jpg",
//        "https://im.runware.ai/image/ws/2/ii/6b69cbd8-d1f3-4b0b-bbe2-d77a658804d8.jpg",
//        "https://im.runware.ai/image/ws/2/ii/6b69cbd8-d1f3-4b0b-bbe2-d77a658804d8.jpg",
//        "https://im.runware.ai/image/ws/2/ii/01996729-9b04-4960-ad1c-e69e52820443.jpg"
//    ]
//    
//    struct Activity: Identifiable {
//        let id = UUID()
//        let title: String
//        let xp: Int
//        let emoji: String
//    }
//
//    let sampleActivities = [
//        Activity(title: "Traveling to New York City for a tech conference", xp: 10, emoji: "✈️"),
//        Activity(title: "Completed a 5k run in the morning", xp: 5, emoji: "❤️"),
//        Activity(title: "Read a chapter of a programming book", xp: 3, emoji: "📚"),
//        Activity(title: "Cooked a healthy dinner for the family", xp: 8, emoji: "🥗"),
//        Activity(title: "Attended a SwiftUI meetup and networked", xp: 12, emoji: "🏆"),
//        Activity(title: "Finished a meditation session", xp: 4, emoji: "🧘"),
//        Activity(title: "Explored a new hiking trail", xp: 15, emoji: "🌲"),
//        
//        Activity(title: "Traveling to New York City for a tech conference", xp: 10, emoji: "✈️"),
//        Activity(title: "Completed a 5k run in the morning", xp: 5, emoji: "❤️"),
//        Activity(title: "Read a chapter of a programming book", xp: 3, emoji: "📚"),
//        Activity(title: "Cooked a healthy dinner for the family", xp: 8, emoji: "🥗"),
//        Activity(title: "Attended a SwiftUI meetup and networked", xp: 12, emoji: "🏆"),
//        Activity(title: "Finished a meditation session", xp: 4, emoji: "🧘"),
//        Activity(title: "Explored a new hiking trail", xp: 15, emoji: "🌲"),
//        
//        Activity(title: "Finished a meditation session", xp: 4, emoji: "🧘"),
//        Activity(title: "Explored a new hiking trail", xp: 15, emoji: "🌲")
//    ]
//    
//    let gridColumns = [
//        GridItem(.flexible(), spacing: 2),
//        GridItem(.flexible(), spacing: 2),
//        GridItem(.flexible(), spacing: 2)
//    ]
//    
//    var itemWidth: CGFloat {
//        let screenWidth = UIScreen.main.bounds.width
//        return (screenWidth - 2 * spacing) / 3
//    }
//    
//    @State private var useGhibli = false // <- Toggle state
//    
//    var displayedImages: [String] {
//        useGhibli ? imageURLsGhibli : galleryImages
//    }
//    
//    var body: some View {
//        NavigationView {
//            ZStack{
//                
//                ScrollView {
//                    
//                    HStack{
//                        
//                        Text("📓 Journal")
//                            .font(.largeTitle)
//                            .fontWeight(.bold)
//                        
//                        Spacer()
//                        
////                        NavigationLink(destination: CharacterProfileView()) {
////                            Image(systemName: "person.crop.circle")
////                                .resizable()
////                                .frame(width: 26, height: 26)
////                                .foregroundColor(Color.accentColor)
//////                                .foregroundColor(.gray)
////                        }
//                        
////                        // Grid view button
////                        Button(action: {
////                            showCameraSheet = true
////                        }) {
////                            Image(systemName: "camera")
////                                .font(.title2)
////                                .foregroundColor(.accentColor)
////                        }
//                        
////                        // Grid view button
////                        Button(action: {
////                            isGridView = true
////                        }) {
////                            Image(systemName: "square.grid.2x2")
////                                .font(.title2)
////                                .foregroundColor(isGridView ? .accentColor : .secondary)
////                        }
////
////                        // List view button
////                        Button(action: {
////                            isGridView = false
////                        }) {
////                            Image(systemName: "rectangle.stack")
////                                .font(.title2)
////                                .foregroundColor(!isGridView ? .accentColor : .secondary)
////                        }
//                        
//                    }
//                    .padding()
//                    
//                    VStack{
//                        Text(buildInstructionText())
//                            .font(.subheadline)
//                            .foregroundColor(.secondary)
//                            .onTapGesture {
//                                navigateToProfile = true
//                            }
//                    }
//                    .padding(.bottom, 20)
//                    .padding(.horizontal)
//                    
//                    // Hidden NavigationLink triggered by state
//                    NavigationLink(
//                        destination: CharacterProfileView(),
//                        isActive: $navigateToProfile,
//                        label: { EmptyView() }
//                    )
//
//                    
////                    VStack{
////                        // Instructions
////                        Text("This is a space that displays your life captured through photos. Record anything, from the mundane to the interesting. Earn points for each photo you add to increase your character stats.")
////                            .font(.subheadline)
////                            .foregroundColor(.secondary)
////
////                        // Text link to go to Character Stats
////                        NavigationLink(destination: CharacterProfileView()) {
////                            Text("character stats.")
////                                .font(.subheadline)
////                                .foregroundColor(.blue)
////                        }
////                    }
////                    .padding(.top, -20)
////                    .padding()
//                    
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
//                    
////                    // Add Journal Entry
////                    NavigationLink(destination: AddQuest()) {
////                        VStack(spacing: 12) {
////                            Image(systemName: "plus")
////                                .font(.system(size: 35))
////                                .foregroundColor(accentColorName.toColor())
////
////                            Text("Add New Journal Entry")
////                                .font(.headline)
////                                .foregroundColor(accentColorName.toColor())
////                        }
////                        .frame(height: 125) // match your quest image height
////                        .frame(maxWidth: .infinity)
////                        .background(
////                            RoundedRectangle(cornerRadius: 12)
////                                .stroke(style: StrokeStyle(lineWidth: 2, dash: [8]))
////                                .foregroundColor(Color.gray)
////                        )
////                        .padding(.horizontal)
////                    }
////                    .padding(.bottom, 12)
//                    
//                    
//                    
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
//                    
//                    
//                    
//                    
//                }
//                
////            // FAB (Floating Action Button)
////               VStack {
////                   Spacer()
////                   HStack {
////                       Spacer()
////                       Button(action: {
////                           print("Camera tapped!")
////                           showCameraSheet = true
////                       }) {
////                           Image(systemName: "camera.fill")
////                               .font(.system(size: 24))
////                               .foregroundColor(.black)
////                               .padding()
////                               .background(Color.accentColor)
////                               .clipShape(Circle())
////                               .shadow(radius: 4)
////                       }
////                       .padding()
////                       Spacer()
////                   }
////               }
//                
//                
//            }
////            .navigationTitle("Your Gallery")
//            .toolbar {
////                ToolbarItem(placement: .navigationBarTrailing) {
////                    Toggle(isOn: $useGhibli) {
////                        EmptyView() // no text, just the switch
////                    }
////                    .toggleStyle(SwitchToggleStyle()) // ensures it looks like a standard iOS switch
////                }
//            }
//            .onAppear {
//                viewModel.loadGalleryImages()
//                loadGalleryImages()
//            }
//            // ✅ Attach the sheet here
//            .sheet(isPresented: $showCameraSheet) {
//                NavigationView {
//                    CameraButtonView()
////                        .navigationTitle("Take a Photo")
////                        .navigationBarTitleDisplayMode(.inline)
////                        .toolbar {
////                            ToolbarItem(placement: .cancellationAction) {
////                                Button("Close") {
////                                    showCameraSheet = false
////                                }
////                            }
////                        }
//                }
//            }
//
//        }
//
//    }
//}
//
//func buildInstructionText() -> AttributedString {
//    var attributed = AttributedString("Document your life through photos. Record anything, from the mundane to the interesting. Earn points for each photo you add to increase your ")
//    var linkPart = AttributedString("character stats.")
//    linkPart.foregroundColor = .blue
////    linkPart.underlineStyle = .single
//    // Append the tappable part
//    attributed.append(linkPart)
//    return attributed
//}
//
//struct FullscreenImageView: View {
//    let urlString: String
//    
//    var body: some View {
//        ZStack {
//            Color.black.ignoresSafeArea()
//            
//            if let url = URL(string: urlString) {
//                AsyncImage(url: url) { phase in
//                    switch phase {
//                    case .empty:
//                        ProgressView()
//                            .scaleEffect(1.2)
//                    case .success(let image):
//                        image
//                            .resizable()
//                            .scaledToFit()
//                            .frame(maxWidth: .infinity, maxHeight: .infinity)
//                            .ignoresSafeArea()
//                    case .failure(_):
//                        VStack(spacing: 12) {
//                            Image(systemName: "exclamationmark.triangle")
//                            Text("Failed to load")
//                        }
//                        .foregroundColor(.white.opacity(0.8))
//                    @unknown default:
//                        EmptyView()
//                    }
//                }
//            }
//        }
//        .navigationBarTitleDisplayMode(.inline)
//    }
//}
