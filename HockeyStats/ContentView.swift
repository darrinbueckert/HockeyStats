import SwiftUI
import SwiftData
import UIKit

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Team.name) private var teams: [Team]

    @State private var showingAddTeam = false
    @State private var teamToDelete: Team?
    @State private var showingDeleteTeamAlert = false

    var body: some View {
        NavigationStack {
            List {
                if teams.isEmpty {
                    ContentUnavailableView(
                        "No Teams Yet",
                        systemImage: "person.3",
                        description: Text("Tap the plus button to add your first team.")
                    )
                } else {
                    ForEach(teams) { team in
                        NavigationLink(destination: TeamRosterView(team: team)) {
                            HStack(spacing: 14) {
                                if let data = team.logoData,
                                   let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 56, height: 56)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                } else {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.15))
                                        .frame(width: 56, height: 56)
                                        .overlay(
                                            Image(systemName: "photo")
                                                .foregroundStyle(.secondary)
                                        )
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(team.name)
                                        .font(.headline)

                                    Text("\(team.players.count) players • \(team.games.count) games")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .onDelete(perform: deleteTeams)
                }
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
            .alert(
                teamDeleteTitle,
                isPresented: $showingDeleteTeamAlert
            ) {
                Button("Delete Team", role: .destructive) {
                    if let team = teamToDelete {
                        context.delete(team)
                    }
                    teamToDelete = nil
                }

                Button("Cancel", role: .cancel) {
                    teamToDelete = nil
                }
            } message: {
                Text("This will permanently delete the team, roster, games, and all related stats. This cannot be undone.")
            }
        }
    }

    private var teamDeleteTitle: String {
        guard let team = teamToDelete else {
            return "Delete Team?"
        }
        return "Delete \(team.name)?"
    }

    private func deleteTeams(at offsets: IndexSet) {
        guard let index = offsets.first else { return }
        teamToDelete = teams[index]
        showingDeleteTeamAlert = true
    }
}

#Preview {
    ContentView()
}
