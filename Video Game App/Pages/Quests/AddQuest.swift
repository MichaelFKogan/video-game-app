import SwiftUI

struct AddQuest: View {
    @AppStorage("accentColorName") private var accentColorName: String = "blue"
    
    @State private var questTitle: String = ""
    @State private var questDescription: String = ""
    @State private var showAlert: Bool = false
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 20) {
                    
                    HStack {
                        Text("⚔️ Create A Side Quest")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Spacer()
                    }
                    .padding()
                    
                    // Instructions box
                    VStack(alignment: .leading, spacing: 8) {
                        Text("📸 Instructions")
                            .font(.headline)
                            .foregroundColor(accentColorName.toColor())
                        Text("Start your quest by giving it a title and, if you’d like, a short description. Adding photos is optional, you can document your journey along the way, or take a photo when you complete the task. Your progress will be tracked and points awarded automatically. It doesn’t matter how small or large your side quest is, every step counts, and points will be given automatically.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, -20)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    
                    // Quest Input Fields
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Quest Title *")
                            .font(.headline)
                            .foregroundColor(accentColorName.toColor())
                        
                        TextField("Enter quest title", text: $questTitle)
                            .textFieldStyle(.roundedBorder)
                        
                        Text("Description (optional)")
                            .font(.headline)
                            .foregroundColor(accentColorName.toColor())
                        
                        TextEditor(text: $questDescription)
                            .frame(height: 100)
                            .padding(4)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal)
                    
                    // Save Quest Button
                    Button(action: {
                        if questTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            showAlert = true
                        } else {
                            // Save the quest here (e.g., append to a list or call your model)
                            print("Quest Saved: \(questTitle), Description: \(questDescription)")
                            dismiss() // Close the sheet
                        }
                    }) {
                        Text("Save Quest")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(accentColorName.toColor())
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .alert("Please enter a quest title", isPresented: $showAlert) {
                        Button("OK", role: .cancel) {}
                    }
                    
                    Spacer()
                }
            }
        }
    }
}
