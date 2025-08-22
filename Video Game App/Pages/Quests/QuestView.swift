import SwiftUI

struct Quest: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let imageURL: String
}

struct QuestView: View {
    @AppStorage("accentColorName") private var accentColorName: String = "blue"
    @State private var isGridView: Bool = false // Track current view
    
    @State private var showAddQuestSheet = false
    
    // Dummy quests (everyday life / fun video game style)
    let quests: [Quest] = [
        Quest(
            title: "Morning Commute Quest",
            description: "Board the metal chariot (your car) and navigate the perilous highway to reach the Fortress of Work on time!",
            imageURL: "https://im.runware.ai/image/ws/2/ii/a955ce72-71c2-40c1-b707-d89f8fe98416.jpg"
        ),
        Quest(
            title: "Snack Acquisition Mission",
            description: "Procure the mystical energy provisions (lunch) from the local merchant before the midday boss fight ensues!",
            imageURL: "https://im.runware.ai/image/ii/8d6e72ea-0ac1-41a6-a4a1-369536344ce7.JPEG?_gl=1*1ynnsuc*_gcl_au*MTg3MTQzMjg3My4xNzU1MzYwNDA3"
        ),
        Quest(
            title: "City Dungeon Patrol",
            description: "Traverse the bustling streets of the metropolis and return to your dwelling without losing any precious items!",
            imageURL: "https://im.runware.ai/image/ws/2/ii/9139c938-47a8-4957-bffd-b9bf0289279c.jpg"
        )
    ]

    // Dummy XP values
    let xpValues: [Int] = [50, 30, 40]
    
    var body: some View {
        NavigationView {
            ZStack{
                ScrollView {
                    VStack(spacing: 20) {
                        
                        HStack {
                            Text("⚔️ Side Quests")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            Spacer()
                            
                        // + Add Quest
                            Button(action: {
                                showAddQuestSheet = true
                            }) {
                                Image(systemName: "plus")
                                    .font(.largeTitle)
                                    .foregroundColor(.accentColor)
                            }
                            
                            
//                            NavigationLink(destination: AddQuest()) {
//                                Image(systemName: "plus")
//                                    .font(.largeTitle)
//                                    .foregroundColor(!isGridView ? .accentColor : .secondary)
//                            }
                            
                        }
                        .padding()
                        
                    // Description
                        Text("Take on fun side quests from your daily life, complete challenges, and earn XP along the way. Turn errands and everyday tasks into epic missions worthy of your adventure log. Create your own quest, or pick from a list of pre-generated side missions. Capture the moment, earn points, and level up your storyline one challenge at a time.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.top, -20)
                        
//                    // + Add New Challenge
//                        NavigationLink(destination: AddQuest()) {
//                            VStack(spacing: 12) {
//                                Image(systemName: "plus")
//                                    .font(.system(size: 35))
//                                    .foregroundColor(accentColorName.toColor())
//    
//                                Text("Add A Quest")
//                                    .font(.headline)
//                                    .foregroundColor(accentColorName.toColor())
//                            }
//                            .frame(height: 125) // match your quest image height
//                            .frame(maxWidth: .infinity)
//                            .background(
//                                RoundedRectangle(cornerRadius: 12)
//                                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [8]))
//                                    .foregroundColor(Color.gray)
//                            )
//                            .padding(.horizontal)
//                        }
                        
                        
                        ForEach(Array(quests.enumerated()), id: \.element.id) { index, quest in
                            NavigationLink(destination: QuestDetailView(quest: quest)) {
                                VStack(alignment: .leading) {
                                    // Quest Title
                                    Text(quest.title)
                                        .font(.headline)
                                        .padding(.leading)
                                    
                                    // Quest Image with XP overlay
                                    if let url = URL(string: quest.imageURL) {
                                        ZStack(alignment: .topTrailing) {
                                            AsyncImage(url: url) { phase in
                                                switch phase {
                                                case .empty:
                                                    ProgressView()
                                                        .frame(height: 250)
                                                case .success(let image):
                                                    image
                                                        .resizable()
                                                        .scaledToFill()
                                                        .frame(height: 250)
                                                        .clipped()
                                                case .failure(_):
                                                    Rectangle()
                                                        .fill(Color.gray.opacity(0.3))
                                                        .frame(height: 250)
                                                        .overlay(Text("Failed to load"))
                                                @unknown default:
                                                    EmptyView()
                                                }
                                            }
                                            .cornerRadius(10)
                                            
                                            // XP Badge
                                            HStack(spacing: 4) {
                                                Image(systemName: "star.fill")
                                                    .foregroundColor(.yellow).opacity(0.8)
                                                Text("\(xpValues[index]) XP")
                                                    .font(.caption)
                                                    .bold()
                                                    .foregroundColor(.white).opacity(0.8)
                                            }
                                            .padding(6)
                                            .background(Color.black.opacity(0.7))
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .padding(8)
                                        }
                                        .padding(.horizontal)
                                    }
                                    
                                    // Quest Description
                                    Text(quest.description)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.leading)
                                        .padding([.horizontal, .top, .bottom])
                                }
                                .padding(.top, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                                )
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                
//            // FAB (Floating Action Button)
//               VStack {
//                   Spacer()
//                   HStack {
//                       Spacer()
//                       Button(action: {
//                           print("Camera tapped!")
//                           // TODO: Open camera / photo picker here
//                       }) {
//                           Image(systemName: "plus")
//                               .font(.system(size: 24))
//                               .fontWeight(.bold)
//                               .foregroundColor(.black)
//                               .padding()
//                               .background(Color.accentColor)
//                               .clipShape(Circle())
//                               .shadow(radius: 4)
//                       }
//                       .padding()
//                   }
//               }
                
                
            }
//            .navigationTitle("Quests")
            // ✅ Attach the sheet here
            .sheet(isPresented: $showAddQuestSheet) {
                NavigationView {
                    AddQuest()  // your camera content
                }
            }
            
        }
    }
}
