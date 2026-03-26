import SwiftUI
import SwiftData

struct TeamRosterView: View {
    @Environment(\.modelContext) private var context

    let team: Team

    @State private var showingAddPlayer = false
    @State private var showingAddGame = false
    @State private var editingPlayer: Player?
    @State private var playerToDelete: Player?
    @State private var showingDeleteAlert = false

    var body: some View {
        List {
            Section("Roster") {
                if team.players.isEmpty {
                    Text("No players yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sortedPlayers) { player in
                        Button {
                            editingPlayer = player
                        } label: {
                            HStack {
                                Text("#\(player.number)")
                                    .bold()
                                    .foregroundStyle(.primary)

                                Text(player.name)
                                    .foregroundStyle(.primary)

                                Spacer()

                                Text(player.position.shortLabel)
                                    .foregroundStyle(.secondary)

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete(perform: deletePlayers)
                }
            }

            Section("Games") {
                if team.games.isEmpty {
                    Text("No games yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sortedGames) { game in
                        NavigationLink(destination: GameDetailView(game: game)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("vs \(game.opponent)")
                                    .font(.headline)

                                Text(game.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete(perform: deleteGames)
                }
            }
        }
        .navigationTitle(team.name)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                NavigationLink(destination: TeamSeasonStatsView(team: team)) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                }

                Button {
                    showingAddGame = true
                } label: {
                    Image(systemName: "sportscourt")
                }

                Button {
                    showingAddPlayer = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddPlayer) {
            AddPlayerView(team: team)
        }
        .sheet(isPresented: $showingAddGame) {
            AddGameView(team: team)
        }
        .sheet(item: $editingPlayer) { player in
            EditPlayerView(player: player)
        }
        .alert("Delete Player?", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let player = playerToDelete {
                    context.delete(player)
                }
                playerToDelete = nil
            }

            Button("Cancel", role: .cancel) {
                playerToDelete = nil
            }
        } message: {
            Text("Deleting this player may affect existing game stats. This cannot be undone.")
        }
    }

    private var sortedPlayers: [Player] {
        team.players.sorted {
            if $0.positionRaw == $1.positionRaw {
                if $0.number == $1.number {
                    return $0.name < $1.name
                }
                return $0.number < $1.number
            }
            return sortOrder(for: $0.position) < sortOrder(for: $1.position)
        }
    }

    private func sortOrder(for position: PlayerPosition) -> Int {
        switch position {
        case .forward: return 0
        case .defense: return 1
        case .goalie: return 2
        case .unknown: return 3
        }
    }

    private var sortedGames: [Game] {
        team.games.sorted { $0.date > $1.date }
    }

    private func deletePlayers(at offsets: IndexSet) {
        guard let index = offsets.first else { return }
        playerToDelete = sortedPlayers[index]
        showingDeleteAlert = true
    }

    private func deleteGames(at offsets: IndexSet) {
        for index in offsets {
            let game = sortedGames[index]
            context.delete(game)
        }
    }
}
