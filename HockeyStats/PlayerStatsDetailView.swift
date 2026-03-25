import SwiftUI

struct PlayerStatsDetailView: View {
    let player: Player
    let team: Team

    private var seasonStats: PlayerSeasonStats {
        StatsCalculator.seasonStats(for: player, on: team)
    }

    private var gameStats: [PlayerGameStats] {
        StatsCalculator.gameStats(for: player, on: team)
    }

    private var playerNotes: [(game: Game, event: GameEvent)] {
        StatsCalculator.notes(for: player, on: team)
    }

    var body: some View {
        List {
            Section("Season Totals") {
                statRow("Games Played", "\(seasonStats.gamesPlayed)")
                statRow("Goals", "\(seasonStats.goals)")
                statRow("Assists", "\(seasonStats.assists)")
                statRow("Points", "\(seasonStats.points)")
                statRow("Shots", "\(seasonStats.shots)")
                statRow("PIM", "\(seasonStats.pim)")
                statRow("Plus", "\(seasonStats.plus)")
                statRow("Minus", "\(seasonStats.minus)")
                statRow("Plus/Minus", "\(seasonStats.plusMinus)")
                statRow("PP Goals", "\(seasonStats.ppGoals)")
                statRow("SH Goals", "\(seasonStats.shGoals)")
            }

            Section("Per Game") {
                if gameStats.isEmpty {
                    Text("No stats yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(gameStats) { stat in
                        VStack(alignment: .leading, spacing: 6) {
                            Text("vs \(stat.game.opponent)")
                                .font(.headline)

                            Text(stat.game.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            HStack(spacing: 12) {
                                Text("G \(stat.goals)")
                                Text("A \(stat.assists)")
                                Text("P \(stat.points)")
                                Text("S \(stat.shots)")
                                Text("PIM \(stat.pim)")
                                Text("+/- \(stat.plusMinus)")
                            }
                            .font(.subheadline)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }

            Section("Notes") {
                if playerNotes.isEmpty {
                    Text("No notes")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(playerNotes.enumerated()), id: \.offset) { _, item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("vs \(item.game.opponent)")
                                .font(.headline)

                            Text(item.event.timestamp.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            if let note = item.event.noteText {
                                Text(note)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .navigationTitle("#\(player.number) \(player.name)")
    }

    @ViewBuilder
    private func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}
