import SwiftUI
import SwiftData
import UIKit

struct TeamGamesView: View {
    @Environment(\.modelContext) private var context

    let team: Team

    @State private var showingAddGame = false
    @State private var editingGame: Game?
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
                if sortedGames.isEmpty {
                    emptyState
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
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button {
                                editingGame = game
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)

                            Button(role: .destructive) {
                                gameToDelete = game
                                showingDeleteGameAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            } header: {
                sectionHeader("Games")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Games")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddGame = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddGame) {
            AddGameView(team: team)
        }
        .sheet(item: $editingGame) { game in
            EditGameView(game: game)
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
                    statPill(recordText)
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

                Text(game.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let result = resultLetter(for: game) {
                Text(result)
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color(.tertiarySystemGroupedBackground))
                    )
                    .foregroundStyle(.primary)
            }

            if let teamScore = game.teamScore,
               let opponentScore = game.opponentScore {
                Text("\(teamScore)-\(opponentScore)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color(.tertiarySystemGroupedBackground))
                    )
                    .foregroundStyle(.primary)
            }

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

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "sportscourt")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text("No games yet")
                .font(.headline)

            Text("Add your first game to start tracking stats.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showingAddGame = true
            } label: {
                Label("Add Game", systemImage: "plus")
                    .font(.subheadline)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.accentColor.opacity(0.15))
                    )
            }
            .padding(.top, 4)
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

    private func resultLetter(for game: Game) -> String? {
        guard let teamScore = game.teamScore,
              let opponentScore = game.opponentScore else {
            return nil
        }

        if teamScore > opponentScore { return "W" }
        if teamScore < opponentScore { return "L" }
        return "T"
    }

    private var sortedGames: [Game] {
        team.games.sorted { $0.date > $1.date }
    }

    private var scoredGames: [Game] {
        team.games.filter { $0.teamScore != nil && $0.opponentScore != nil }
    }

    private var wins: Int {
        scoredGames.filter { ($0.teamScore ?? 0) > ($0.opponentScore ?? 0) }.count
    }

    private var losses: Int {
        scoredGames.filter { ($0.teamScore ?? 0) < ($0.opponentScore ?? 0) }.count
    }

    private var ties: Int {
        scoredGames.filter { ($0.teamScore ?? 0) == ($0.opponentScore ?? 0) }.count
    }

    private var recordText: String {
        if scoredGames.isEmpty {
            return "No record yet"
        }
        return "\(wins)-\(losses)-\(ties)"
    }

    private var gameDeleteTitle: String {
        guard let game = gameToDelete else {
            return "Delete Game?"
        }

        let dateText = game.date.formatted(date: .abbreviated, time: .omitted)
        return "Delete game vs \(game.opponent) on \(dateText)?"
    }
}
