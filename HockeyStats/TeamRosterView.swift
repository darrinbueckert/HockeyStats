import SwiftUI
import SwiftData
import UIKit

struct TeamRosterView: View {
    @Environment(\.modelContext) private var context

    let team: Team

    @State private var showingAddPlayer = false
    @State private var showingAddGame = false
    @State private var showingEditTeam = false
    @State private var editingPlayer: Player?
    @State private var playerToDelete: Player?
    @State private var showingDeletePlayerAlert = false
    @State private var gameToDelete: Game?
    @State private var showingDeleteGameAlert = false

    var body: some View {
        List {
            Section {
                teamHeader
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            Section {
                if team.players.isEmpty {
                    emptyStateRow(
                        icon: "person.3",
                        title: "No players yet",
                        subtitle: "Tap the plus button to add your roster."
                    )
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(sortedPlayers) { player in
                        Button {
                            editingPlayer = player
                        } label: {
                            playerRow(for: player)
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                    .onDelete(perform: deletePlayers)
                }
            } header: {
                sectionHeader("Roster")
            }

            Section {
                if team.games.isEmpty {
                    emptyStateRow(
                        icon: "sportscourt",
                        title: "No games yet",
                        subtitle: "Tap the court button to add your first game."
                    )
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(sortedGames) { game in
                        NavigationLink(destination: GameDetailView(game: game)) {
                            gameRow(for: game)
                        }
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                    .onDelete(perform: deleteGames)
                }
            } header: {
                sectionHeader("Games")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(team.name)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    showingEditTeam = true
                } label: {
                    Image(systemName: "pencil")
                }

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
        .sheet(isPresented: $showingEditTeam) {
            EditTeamView(team: team)
        }
        .sheet(item: $editingPlayer) { player in
            EditPlayerView(player: player)
        }
        .alert(
            playerDeleteTitle,
            isPresented: $showingDeletePlayerAlert
        ) {
            Button("Delete Player", role: .destructive) {
                if let player = playerToDelete {
                    context.delete(player)
                }
                playerToDelete = nil
            }

            Button("Cancel", role: .cancel) {
                playerToDelete = nil
            }
        } message: {
            Text("Deleting this player may affect existing game stats and cannot be undone.")
        }
        .alert(
            gameDeleteTitle,
            isPresented: $showingDeleteGameAlert
        ) {
            Button("Delete Game", role: .destructive) {
                if let game = gameToDelete {
                    context.delete(game)
                }
                gameToDelete = nil
            }

            Button("Cancel", role: .cancel) {
                gameToDelete = nil
            }
        } message: {
            Text("This will permanently delete the game and all events/stat data attached to it. This cannot be undone.")
        }
    }

    private var teamHeader: some View {
        HStack(spacing: 16) {
            if let data = team.logoData,
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 78, height: 78)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    )
            } else {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.gray.opacity(0.12))
                    .frame(width: 78, height: 78)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 26))
                            .foregroundStyle(.secondary)
                    )
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(team.name)
                    .font(.title2)
                    .fontWeight(.bold)

                HStack(spacing: 8) {
                    statPill("\(team.players.count) players")
                    statPill("\(team.games.count) games")
                }
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .contentShape(Rectangle())
        .onTapGesture {
            showingEditTeam = true
        }
    }

    private func playerRow(for player: Player) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .frame(width: 52, height: 52)

                Text("#\(player.number)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.7)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(player.name)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(positionFullLabel(for: player.position))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(player.position.shortLabel)
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color(.tertiarySystemGroupedBackground))
                )
                .foregroundStyle(.primary)

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private func gameRow(for game: Game) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .frame(width: 52, height: 52)

                Image(systemName: "sportscourt")
                    .font(.title3)
                    .foregroundStyle(.primary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("vs \(game.opponent)")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(game.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private func emptyStateRow(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.secondary)

            Text(title)
                .font(.headline)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .textCase(nil)
    }

    private func statPill(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color(.tertiarySystemGroupedBackground))
            )
    }

    private func positionFullLabel(for position: PlayerPosition) -> String {
        switch position {
        case .forward:
            return "Forward"
        case .defense:
            return "Defense"
        case .goalie:
            return "Goalie"
        case .unknown:
            return "Unknown"
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

    private var sortedGames: [Game] {
        team.games.sorted { $0.date > $1.date }
    }

    private var playerDeleteTitle: String {
        guard let player = playerToDelete else {
            return "Delete Player?"
        }
        return "Delete #\(player.number) \(player.name)?"
    }

    private var gameDeleteTitle: String {
        guard let game = gameToDelete else {
            return "Delete Game?"
        }

        let dateText = game.date.formatted(date: .abbreviated, time: .omitted)
        return "Delete game vs \(game.opponent) on \(dateText)?"
    }

    private func sortOrder(for position: PlayerPosition) -> Int {
        switch position {
        case .forward: return 0
        case .defense: return 1
        case .goalie: return 2
        case .unknown: return 3
        }
    }

    private func deletePlayers(at offsets: IndexSet) {
        guard let index = offsets.first else { return }
        playerToDelete = sortedPlayers[index]
        showingDeletePlayerAlert = true
    }

    private func deleteGames(at offsets: IndexSet) {
        guard let index = offsets.first else { return }
        gameToDelete = sortedGames[index]
        showingDeleteGameAlert = true
    }
}
