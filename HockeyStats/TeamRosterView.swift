import SwiftUI
import SwiftData

struct TeamRosterView: View {
    @Environment(\.modelContext) private var context

    let team: Team

    @State private var showingAddPlayer = false
    @State private var showingAddGame = false

    var body: some View {
        List {
            Section("Roster") {
                if team.players.isEmpty {
                    Text("No players yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sortedPlayers) { player in
                        HStack {
                            Text("#\(player.number)")
                                .bold()
                            Text(player.name)
                        }
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
                NavigationLink(destination: TeamStatsView(team: team)) {
                    Image(systemName: "chart.bar")
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
    }

    private var sortedPlayers: [Player] {
        team.players.sorted {
            if $0.number == $1.number {
                return $0.name < $1.name
            }
            return $0.number < $1.number
        }
    }

    private var sortedGames: [Game] {
        team.games.sorted { $0.date > $1.date }
    }

    private func deletePlayers(at offsets: IndexSet) {
        for index in offsets {
            let player = sortedPlayers[index]
            context.delete(player)
        }
    }

    private func deleteGames(at offsets: IndexSet) {
        for index in offsets {
            let game = sortedGames[index]
            context.delete(game)
        }
    }
}
