import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Team.name) private var teams: [Team]

    @State private var showingAddTeam = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(teams) { team in
                    NavigationLink(destination: TeamRosterView(team: team)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(team.name)
                                .font(.headline)
                            Text("\(team.players.count) players")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete(perform: deleteTeams)
            }
            .navigationTitle("Teams")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddTeam = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTeam) {
                AddTeamView()
            }
        }
    }

    private func deleteTeams(at offsets: IndexSet) {
        for index in offsets {
            context.delete(teams[index])
        }
    }
}

#Preview {
    ContentView()
}
