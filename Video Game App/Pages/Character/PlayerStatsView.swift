import SwiftUI

struct PlayerStatsView: View {
    var level: Int

    // Mockup stats for demo
    private let stats: [(label: String, value: Int, color: Color)] = [
        ("📓 Journal Entries", 42, .indigo),
         ("⚔️ Quests Completed", 18, .mint),
        ("❤️ HP", 75, .red),
        ("⚡️ Energy", 50, .yellow),
        ("✨ XP", 120, .blue),
        ("🌍 Adventure", 80, .green),
        ("🛡 Armor", 60, .gray),
        ("💪 Strength", 90, .orange),
        ("🧠 Intelligence", 70, .purple),
        ("🏃‍♂️ Agility", 85, .pink),
        ("🩸 Stamina", 55, .brown),
        ("💧 Hydration", 95, .cyan),
        ("🔥 Motivation", 80, .red.opacity(0.7)),
        ("🎯 Accuracy", 65, .yellow.opacity(0.7)),
        ("💰 Gold", 40, .orange.opacity(0.7)),
        ("🏆 Achievements", 30, .blue.opacity(0.7)),
        ("🗺 Exploration", 90, .green.opacity(0.7)),
        ("💡 Creativity", 75, .purple.opacity(0.7)),
        ("❤️ Friendship", 50, .pink.opacity(0.7)),
        ("🧘‍♂️ Focus", 85, .teal),
        ("🎮 Luck", 60, .yellow.opacity(0.5)),
        ("🔧 Crafting", 70, .gray.opacity(0.5))
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Level badge
                Text("Level \(level)")
                    .font(.headline)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 16)
//                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(12)

                // Stat bars (2 per row)
                VStack(spacing: 12) {
                    ForEach(0..<stats.count/2, id: \.self) { row in
                        HStack(spacing: 12) {
                            StatBar(label: stats[row*2].label,
                                    value: stats[row*2].value,
                                    color: stats[row*2].color)
                            StatBar(label: stats[row*2+1].label,
                                    value: stats[row*2+1].value,
                                    color: stats[row*2+1].color)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(16)
            .shadow(radius: 3)
            .padding()
        }
        .padding(.bottom, 200)
    }
}

struct StatBar: View {
    var label: String
    var value: Int
    var color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(label): \(value)")
                .font(.caption)
                .bold()
            ProgressView(value: Double(value % 100) / 100.0)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .frame(height: 8)
                .cornerRadius(4)
        }
        .frame(maxWidth: .infinity)
    }
}

