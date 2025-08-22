import SwiftUI

struct LoadingPhotoPlaceholder: View {
    let width: CGFloat
    let height: CGFloat
    @State private var progress: Double = 0.0
    
    var body: some View {
        ZStack {
            // Gray background rectangle
            Rectangle()
                .fill(Color(.systemGray5))
                .frame(width: width, height: height)
                .cornerRadius(8)
            
            // Loading content
            VStack(spacing: 12) {
                // Progress indicator
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                    .scaleEffect(1.2)
                
                // Loading text
                Text("Transforming...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fontWeight(.medium)
                
                // Animated dots
                HStack(spacing: 4) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 4, height: 4)
                            .scaleEffect(progress > Double(index) * 0.3 ? 1.2 : 0.8)
                            .animation(
                                .easeInOut(duration: 0.6)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                                value: progress
                            )
                    }
                }
            }
        }
        .onAppear {
            // Start the animation
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                progress = 1.0
            }
        }
    }
}

#Preview {
    LoadingPhotoPlaceholder(width: 120, height: 200)
        .padding()
}
