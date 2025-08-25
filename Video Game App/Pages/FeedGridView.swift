import SwiftUI
import Supabase

struct FeedGridView: View {
    @StateObject private var viewModel: FeedViewModel
    @State private var showingComments = false
    @State private var selectedPost: Post?
    @State private var showingUserProfile = false
    @State private var selectedUsername: String?
    @AppStorage("accentColorName") private var accentColorName: String = "blue"
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 3)
    let spacing: CGFloat = 2
    
    init(client: SupabaseClient) {
        _viewModel = StateObject(wrappedValue: FeedViewModel(client: client))
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { proxy in
                let horizontalOuterPadding: CGFloat = spacing
                let totalInteritemSpacing = spacing * CGFloat(columns.count - 1)
                let contentWidth = proxy.size.width - (horizontalOuterPadding * 2)
                let itemWidth = (contentWidth - totalInteritemSpacing) / CGFloat(columns.count)
                
                ZStack {
                    Color(.systemBackground)
                        .ignoresSafeArea()
                    
                    if viewModel.posts.isEmpty && !viewModel.isLoading {
                        emptyStateView
                    } else {
                        feedGridContent(itemWidth: itemWidth)
                    }
                }
//                .navigationTitle("Feed")
                .navigationBarTitleDisplayMode(.large)
                .refreshable {
                    await viewModel.refreshFeed()
                }
                .onAppear {
                    if viewModel.posts.isEmpty {
                        Task {
                            await viewModel.loadFeed()
                        }
                    }
                }
                            .sheet(isPresented: $showingComments) {
                if let post = selectedPost {
                    CommentsView(post: post, client: SupabaseManager.shared.client)
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.visible)
                }
            }
                .background(
                    NavigationLink(
                        destination: Group {
                            if let username = selectedUsername {
                                UserProfileView(username: username, client: SupabaseManager.shared.client)
                            }
                        },
                        isActive: $showingUserProfile
                    ) {
                        EmptyView()
                    }
                )
                .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                    Button("OK") {
                        viewModel.errorMessage = nil
                    }
                } message: {
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                    }
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Posts Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Be the first to share something amazing!")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    
    private func feedGridContent(itemWidth: CGFloat) -> some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: spacing) {
                ForEach(viewModel.posts) { post in
                    FeedGridItemView(
                        post: post,
                        viewModel: viewModel,
                        itemWidth: itemWidth,
                        onLikeTapped: {
                            Task {
                                await viewModel.toggleLike(for: post)
                            }
                        },
                        onCommentTapped: {
                            selectedPost = post
                            showingComments = true
                        },
                        onUsernameTapped: {
                            if let username = post.user_username {
                                selectedUsername = username
                                showingUserProfile = true
                            }
                        }
                    )
                }
                
                if viewModel.hasMorePosts {
                    loadingMoreView
                }
            }
            .padding(.horizontal, spacing)
            .padding(.bottom)
        }
    }
    
    private var loadingMoreView: some View {
        HStack {
            Spacer()
            if viewModel.isLoading {
                ProgressView()
                    .padding()
            }
            Spacer()
        }
        .onAppear {
            Task {
                await viewModel.loadMorePosts()
            }
        }
    }
}

// MARK: - Feed Grid Item View

struct FeedGridItemView: View {
    @AppStorage("accentColorName") private var accentColorName: String = "blue"
    
    let post: Post
    let viewModel: FeedViewModel
    let itemWidth: CGFloat
    let onLikeTapped: () -> Void
    let onCommentTapped: () -> Void
    let onUsernameTapped: () -> Void
    
    var body: some View {
        NavigationLink(destination: FeedDetailView(post: post, viewModel: viewModel)) {
            ZStack(alignment: .bottomLeading) {
                // Image
                CachedAsyncImage(url: post.fullImageURL) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: itemWidth, height: 200)
                        .clipped()
                } placeholder: {
                    ProgressView()
                        .frame(width: itemWidth, height: 200)
                }
                
                // Black gradient overlay
                LinearGradient(
                    colors: [Color.black.opacity(0.8), .clear],
                    startPoint: .bottom,
                    endPoint: .top
                )
                .frame(height: 70)
                .frame(maxWidth: .infinity, alignment: .bottom)
                
                // Title text
                if let title = post.title, !title.isEmpty {
                    Text(title)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .padding([.horizontal, .bottom], 6)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Feed Detail View

struct FeedDetailView: View {
    let post: Post
    let viewModel: FeedViewModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage("accentColorName") private var accentColorName: String = "blue"
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    // User Avatar
                    CachedAsyncImage(url: viewModel.getAvatarURL(for: post)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFill()
                            .foregroundColor(.gray)
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(accentColorName.toColor(), lineWidth: 2)
                    )
                    .padding(2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.getDisplayName(for: post))
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(viewModel.formatTimeAgo(for: post))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                
                // Image
                CachedAsyncImage(url: post.fullImageURL) { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .cornerRadius(10)
                } placeholder: {
                    ProgressView()
                        .frame(height: 300)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal)
                
                // Actions
                HStack(spacing: 16) {
                    Button(action: {
                        Task {
                            await viewModel.toggleLike(for: post)
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: post.is_liked_by_current_user == true ? "heart.fill" : "heart")
                                .foregroundColor(post.is_liked_by_current_user == true ? .red : .primary)
                            
                            Text(viewModel.formatLikeCount(post.like_count))
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                    }
                    
                    Button(action: {}) {
                        HStack(spacing: 4) {
                            Image(systemName: "bubble.right")
                                .foregroundColor(.primary)
                            
                            Text(viewModel.formatCommentCount(post.comment_count))
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                
                // Engagement info
                if let likeCount = post.like_count, likeCount > 0 {
                    HStack {
                        Text("\(viewModel.formatLikeCount(likeCount)) likes")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                }
                
                // Title and Description
                if let title = post.title, !title.isEmpty {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .padding(.horizontal)
                }
                
                if let description = post.description, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.primary).opacity(0.8)
                        .padding(.horizontal)
                }
                
                // Timestamp
                Text(viewModel.formatTimeAgo(for: post))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.bottom)
            }
        }
        .navigationTitle("Post")
        .navigationBarTitleDisplayMode(.inline)
//        .navigationBarBackButtonHidden(true)
//        .toolbar {
//            ToolbarItem(placement: .navigationBarLeading) {
//                Button("Back") {
//                    dismiss()
//                }
//            }
//        }
    }
}
