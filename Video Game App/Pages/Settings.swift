import SwiftUI

struct Settings: View {
    @AppStorage("isDarkMode") private var isDarkMode = true
    @AppStorage("accentColorName") private var accentColorName: String = "blue"

    let themeColors: [String: Color] = [
        "blue": .blue,
        "purple": .purple,
        "pink": .pink,
        "red": .red,
        "orange": .orange,
        "yellow": .yellow,
        
        // "green": .green,
        // "cyan": .cyan,
        // "mint": .mint,
        // "indigo": .indigo,
        // "teal": .teal,
        // "gray": .gray,
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // Dark Mode Toggle
                    Button(action: { isDarkMode.toggle() }) {
                        HStack {
                            Text("Dark Mode")
                                .fontWeight(.semibold)
                            Spacer()
                            Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                                .foregroundColor(isDarkMode ? .purple : .yellow)
                        }
                        .padding()
                        .frame(maxWidth: .infinity) // full-width button
//                        .background(isDarkMode ? Color.black : Color.white)
                        .background(Color(UIColor.systemGray6))
                        .foregroundColor(isDarkMode ? .white : .black)
                        .cornerRadius(12)
                        .shadow(radius: 2)
                    }

                    // Accent Color Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Accent Color")
                            .font(.headline)
                        
                        let themeColorOrder = ["blue", "purple", "pink", "red", "orange", "yellow"] 
                        
                        // ["gray", "green", "indigo", "cyan", "mint", "teal"]

                        // Define flexible columns
                        let columns = [
                            GridItem(.adaptive(minimum: 40), spacing: 15)
                        ]

                        LazyVGrid(columns: columns, spacing: 15) {
                            ForEach(themeColorOrder, id: \.self) { key in
                                Button(action: {
                                    accentColorName = key
                                }) {
                                    Circle()
                                        .fill(themeColors[key]!)
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Circle()
                                                .stroke(accentColorName == key ? Color.white : Color.clear, lineWidth: 3)
                                        )
                                        .shadow(radius: accentColorName == key ? 3 : 0)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.vertical, 5)


                        .padding(.vertical, 5)
                    }
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(12)
                    .shadow(radius: 1)

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Settings")
        }
    }
}
