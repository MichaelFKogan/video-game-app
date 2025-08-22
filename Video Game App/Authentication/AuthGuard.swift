import SwiftUI

struct AuthGuard<Content: View>: View {
    @EnvironmentObject var session: SessionStore
    let content: Content
    @State private var showAuth = false
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            // Always show the content behind
            content
            
            // If not logged in, overlay Auth screen
            if !session.isLoggedIn {
                Color.black.opacity(0.6) // dimmed background
                    .ignoresSafeArea()
                
                VStack {
                    Auth()
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                                .shadow(radius: 10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.accentColor, lineWidth: 2) // 🔵 border
                                )
                        )
                        .padding()
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: session.isLoggedIn)
    }
}
