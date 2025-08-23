import SwiftUI

// MARK: - Cached Async Image Component
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    private let url: URL?
    private let scale: CGFloat
    private let transaction: Transaction
    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder
    
    @State private var loadedImage: UIImage?
    @State private var isLoading = true
    
    init(
        url: URL?,
        scale: CGFloat = 1.0,
        transaction: Transaction = Transaction(),
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.scale = scale
        self.transaction = transaction
        self.content = content
        self.placeholder = placeholder
    }
    
    var body: some View {
        Group {
            if let loadedImage = loadedImage {
                content(Image(uiImage: loadedImage))
            } else {
                placeholder()
            }
        }
        .onAppear {
            loadImage()
        }
        .onChange(of: url) { _ in
            loadImage()
        }
    }
    
    private func loadImage() {
        guard let url = url else {
            isLoading = false
            return
        }
        
        // Check if image is already cached
        if let cachedImage = ImageCache.shared.get(forKey: url.absoluteString) {
            self.loadedImage = cachedImage
            self.isLoading = false
//            print("📸 Loaded from cache: \(url.lastPathComponent)")
            return
        }
        
        isLoading = true
//        print("🌐 Loading from network: \(url.lastPathComponent)")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let data = data, let image = UIImage(data: data) {
                    // Cache the image
                    ImageCache.shared.set(image, forKey: url.absoluteString)
                    self.loadedImage = image
//                    print("💾 Cached image: \(url.lastPathComponent)")
                }
                self.isLoading = false
            }
        }.resume()
    }
}

// MARK: - Image Cache
class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSString, UIImage>()
    
    private init() {
        cache.countLimit = 100 // Maximum number of images to cache
        cache.totalCostLimit = 1024 * 1024 * 100 // 100 MB limit
    }
    
    func set(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
    
    func get(forKey key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }
    
    func remove(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
    }
    
    func removeAll() {
        cache.removeAllObjects()
    }
}

// MARK: - Convenience Initializers
extension CachedAsyncImage where Content == Image, Placeholder == ProgressView<EmptyView, EmptyView> {
    init(url: URL?, scale: CGFloat = 1.0) {
        self.init(url: url, scale: scale) { image in
            image
        } placeholder: {
            ProgressView()
        }
    }
}

extension CachedAsyncImage where Placeholder == ProgressView<EmptyView, EmptyView> {
    init(
        url: URL?,
        scale: CGFloat = 1.0,
        transaction: Transaction = Transaction(),
        @ViewBuilder content: @escaping (Image) -> Content
    ) {
        self.init(url: url, scale: scale, transaction: transaction, content: content) {
            ProgressView()
        }
    }
}
