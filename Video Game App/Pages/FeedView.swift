import SwiftUI
import Supabase

struct FeedView: View {
    @StateObject private var viewModel: FeedViewModel
    @State private var showingComments = false
    @State private var selectedPost: Post?
    @State private var showingUserProfile = false
    @State private var selectedUsername: String?
    
    init(client: SupabaseClient) {
        _viewModel = StateObject(wrappedValue: FeedViewModel(client: client))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                if viewModel.posts.isEmpty && !viewModel.isLoading {
                    emptyStateView
                } else {
                    feedContent
                }
            }
            .navigationTitle("Feed")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await viewModel.refreshFeed()
            }
            .task {
                await viewModel.loadFeed()
            }
            .sheet(isPresented: $showingComments) {
                if let post = selectedPost {
                    CommentsView(post: post, client: SupabaseManager.shared.client)
                }
            }
            .sheet(isPresented: $showingUserProfile) {
                if let username = selectedUsername {
                    UserProfileView(username: username, client: SupabaseManager.shared.client)
                }
            }
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
    
    private var feedContent: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.posts) { post in
                    PostCardView(
                        post: post,
                        viewModel: viewModel,
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
                    .padding(.bottom, 8)
                }
                
                if viewModel.hasMorePosts {
                    loadingMoreView
                }
            }
            .padding(.horizontal)
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

// MARK: - Post Card View

struct PostCardView: View {
    let post: Post
    let viewModel: FeedViewModel
    let onLikeTapped: () -> Void
    let onCommentTapped: () -> Void
    let onUsernameTapped: () -> Void
    
    @State private var imageURL: URL?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            postHeader
            
            // Image
            postImage
            
            // Actions
            postActions
            
            // Engagement
            engagementInfo
            
            // Description
            if let description = post.description, !description.isEmpty {
                postDescription(description)
            }
            
            // Timestamp
            timestampView
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .task {
            await loadImage()
        }
    }
    
    private var postHeader: some View {
        HStack {
            // User Avatar
            AsyncImage(url: viewModel.getAvatarURL(for: post)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.gray)
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Button(action: onUsernameTapped) {
                    Text(viewModel.getDisplayName(for: post))
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                
                Text(viewModel.formatTimeAgo(for: post))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // More options button (for post owner)
            if isCurrentUserPost {
                Menu {
                    Button("Delete", role: .destructive) {
                        Task {
                            await viewModel.deletePost(post)
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }
    
    private var postImage: some View {
        Group {
            if let imageURL = imageURL {
                AsyncImage(url: imageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        )
                }
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                    )
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 400)
        .clipped()
    }
    
    private var postActions: some View {
        HStack(spacing: 16) {
            Button(action: onLikeTapped) {
                HStack(spacing: 4) {
                    Image(systemName: post.is_liked_by_current_user == true ? "heart.fill" : "heart")
                        .foregroundColor(post.is_liked_by_current_user == true ? .red : .primary)
                    
                    Text(viewModel.formatLikeCount(post.like_count))
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
            }
            
            Button(action: onCommentTapped) {
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
        .padding(.horizontal, 16)
    }
    
    private var engagementInfo: some View {
        HStack {
            if let likeCount = post.like_count, likeCount > 0 {
                Text("\(viewModel.formatLikeCount(likeCount)) likes")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
    }
    
    private func postDescription(_ description: String) -> some View {
        HStack(alignment: .top) {
            Text(viewModel.getDisplayName(for: post))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(.horizontal, 16)
    }
    
    private var timestampView: some View {
        Text(viewModel.formatTimeAgo(for: post))
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
    }
    
    private var isCurrentUserPost: Bool {
        // This would need to be implemented based on your auth system
        // For now, we'll assume it's not the current user's post
        return false
    }
    
    private func loadImage() async {
        // Convert the image_url to a full URL
        if let url = URL(string: post.image_url) {
            imageURL = url
        } else {
            // If it's a relative path, construct the full URL
            // This assumes you have a base URL for your images
            let baseURL = "https://your-project.supabase.co/storage/v1/object/public/photos/"
            imageURL = URL(string: baseURL + post.image_url)
        }
    }
}

// MARK: - Comments View

struct CommentsView: View {
    let post: Post
    let client: SupabaseClient
    
    @StateObject private var commentsViewModel = CommentsViewModel()
    @State private var newCommentText = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                if commentsViewModel.comments.isEmpty && !commentsViewModel.isLoading {
                    emptyCommentsView
                } else {
                    commentsList
                }
                
                commentInputView
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await commentsViewModel.loadComments(for: post.id, client: client)
        }
    }
    
    private var emptyCommentsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bubble.right")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Comments Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Be the first to comment!")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var commentsList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                ForEach(commentsViewModel.comments) { comment in
                    CommentRowView(comment: comment)
                }
            }
            .padding()
        }
    }
    
    private var commentInputView: some View {
        HStack {
            TextField("Add a comment...", text: $newCommentText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button("Post") {
                Task {
                    await commentsViewModel.addComment(
                        content: newCommentText,
                        postId: post.id,
                        client: client
                    )
                    newCommentText = ""
                }
            }
            .disabled(newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: -1)
    }
}

// MARK: - Comment Row View

struct CommentRowView: View {
    let comment: Comment
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            AsyncImage(url: URL(string: comment.user_avatar_url ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.gray)
            }
            .frame(width: 32, height: 32)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(comment.user_display_name ?? comment.user_username ?? "Unknown User")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text(formatTimeAgo(for: comment.created_at))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(comment.content)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
        }
    }
    
    private func formatTimeAgo(for date: Date) -> String {
        let timeInterval = Date().timeIntervalSince(date)
        
        if timeInterval < 60 {
            return "Just now"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)m ago"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(timeInterval / 86400)
            return "\(days)d ago"
        }
    }
}

// MARK: - Comments ViewModel

@MainActor
class CommentsViewModel: ObservableObject {
    @Published var comments: [Comment] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let feedService = FeedService(client: SupabaseManager.shared.client)
    
    func loadComments(for postId: UUID, client: SupabaseClient) async {
        isLoading = true
        
        do {
            comments = try await feedService.fetchComments(postId: postId)
        } catch {
            errorMessage = "Failed to load comments: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func addComment(content: String, postId: UUID, client: SupabaseClient) async {
        do {
            let newComment = try await feedService.addComment(postId: postId, content: content)
            comments.append(newComment)
        } catch {
            errorMessage = "Failed to add comment: \(error.localizedDescription)"
        }
    }
}

// MARK: - User Profile View

struct UserProfileView: View {
    let username: String
    let client: SupabaseClient
    
    @StateObject private var profileViewModel = UserProfileViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if let profile = profileViewModel.profile {
                        profileHeader(profile)
                        userPosts(profile)
                    } else if profileViewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        Text("User not found")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await profileViewModel.loadProfile(username: username, client: client)
        }
    }
    
    private func profileHeader(_ profile: UserProfile) -> some View {
        VStack(spacing: 16) {
            AsyncImage(url: URL(string: profile.avatar_url ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.gray)
            }
            .frame(width: 80, height: 80)
            .clipShape(Circle())
            
            VStack(spacing: 4) {
                Text(profile.display_name ?? profile.username ?? "Unknown User")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                if let username = profile.username {
                    Text("@\(username)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            if let bio = profile.bio, !bio.isEmpty {
                Text(bio)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
    }
    
    private func userPosts(_ profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Posts")
                .font(.headline)
                .padding(.horizontal)
            
            if profileViewModel.posts.isEmpty {
                Text("No posts yet")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 3), spacing: 2) {
                    ForEach(profileViewModel.posts) { post in
                        AsyncImage(url: URL(string: post.image_url)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                        }
                        .frame(height: 120)
                        .clipped()
                    }
                }
            }
        }
    }
}

// MARK: - User Profile ViewModel

@MainActor
class UserProfileViewModel: ObservableObject {
    @Published var profile: UserProfile?
    @Published var posts: [Post] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let feedService = FeedService(client: SupabaseManager.shared.client)
    
    func loadProfile(username: String, client: SupabaseClient) async {
        isLoading = true
        
        do {
            profile = try await feedService.fetchUserProfile(username: username)
            
            if let profile = profile {
                posts = try await feedService.fetchUserPosts(userId: profile.id)
            }
        } catch {
            errorMessage = "Failed to load profile: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

// MARK: - Supabase Manager (You'll need to create this)

class SupabaseManager {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    private init() {
        // Initialize your Supabase client here
        // Replace with your actual Supabase URL and anon key
        self.client = SupabaseClient(
            supabaseURL: URL(string: "YOUR_SUPABASE_URL")!,
            supabaseKey: "YOUR_SUPABASE_ANON_KEY"
        )
    }
}
