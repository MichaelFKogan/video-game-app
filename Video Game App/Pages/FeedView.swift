import SwiftUI
import Supabase

struct FeedView: View {
    @StateObject private var viewModel: FeedViewModel
    @State private var showingComments = false
    @State private var selectedPost: Post?
    @State private var showingUserProfile = false
    @State private var selectedUsername: String?
    @AppStorage("accentColorName") private var accentColorName: String = "blue"
    
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
//            .navigationTitle("Feed")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await viewModel.refreshFeed()
            }
            .onAppear {
                // Load feed immediately when view appears
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
    @AppStorage("accentColorName") private var accentColorName: String = "blue"
    
    let post: Post
    let viewModel: FeedViewModel
    let onLikeTapped: () -> Void
    let onCommentTapped: () -> Void
    let onUsernameTapped: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            postHeader
            
            // Image
            postImage
            
            // Actions
            postActions
            
//            // Engagement
//            engagementInfo
            
            // Title and Description (if available) - BELOW the image
            if let title = post.title, !title.isEmpty {
                postTitle(title)
            }
            
            if let description = post.description, !description.isEmpty {
                postDescription(description)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        )

    }
    
    private var postHeader: some View {
        HStack {
            // User Avatar
            Button(action: onUsernameTapped) {
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
            }
            .buttonStyle(PlainButtonStyle())
            
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
        .padding(.top, 18)
    }
    
    private var postImage: some View {
        NavigationLink {
            FeedDetailView(post: post, viewModel: viewModel)
        } label: {
            CachedAsyncImage(url: post.fullImageURL) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(height: 250)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .cornerRadius(10)
            } placeholder: {
                ProgressView()
                    .frame(height: 250)
                    .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.plain)
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
    
    private func postTitle(_ title: String) -> some View {
        NavigationLink {
            FeedDetailView(post: post, viewModel: viewModel)
        } label: {
            HStack(alignment: .top) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Spacer()
            }
            .frame(maxWidth: .infinity, minHeight: 30)
            .padding(.horizontal, 16)
            .padding(.top, 4)
        }
        .buttonStyle(.plain)
    }

    
    private func postDescription(_ description: String) -> some View {
        NavigationLink {
            FeedDetailView(post: post, viewModel: viewModel)
        } label: {
            HStack(alignment: .top) {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.primary).opacity(0.8)
                Spacer()
            }
            .frame(maxWidth: .infinity, minHeight: 20)
            .padding(.horizontal, 16)
            .padding(.top, 2)
        }
        .buttonStyle(.plain)
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
    

}

// MARK: - Comments View

struct CommentsView: View {
    let post: Post
    let client: SupabaseClient
    
    @StateObject private var commentsViewModel = CommentsViewModel()
    @State private var newCommentText = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Comments")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            .padding()
            .background(Color(.systemBackground))
            
            Divider()
            
            // Content
            if commentsViewModel.comments.isEmpty && !commentsViewModel.isLoading {
                emptyCommentsView
            } else {
                commentsList
            }
            
            Divider()
            
            // Input
            commentInputView
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
    @AppStorage("accentColorName") private var accentColorName: String = "blue"
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            CachedAsyncImage(url: URL(string: comment.user_avatar_url ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.gray)
            }
            .frame(width: 32, height: 32)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(accentColorName.toColor(), lineWidth: 1.5)
            )
            .padding(1.5)
            
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
    @AppStorage("accentColorName") private var accentColorName: String = "blue"
    
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
            CachedAsyncImage(url: URL(string: profile.avatar_url ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFill()
                    .foregroundColor(.gray)
            }
            .frame(width: 80, height: 80)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(accentColorName.toColor(), lineWidth: 3)
            )
            .padding(3)
            
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
                Text("User bio here?")
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
                        CachedAsyncImage(url: post.fullImageURL) { image in
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

// MARK: - Helper Functions

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
