import SwiftUI
import SwiftData

struct PlayerGameStatLine: Identifiable {
    let id = UUID()
    let game: Game
    let goals: Int
    let assists: Int
    let shots: Int
    let pim: Int
    let plus: Int
    let minus: Int
    let ppGoals: Int
    let shGoals: Int

    var points: Int { goals + assists }
    var plusMinus: Int { plus - minus }

    var hasStats: Bool {
        goals > 0 || assists > 0 || shots > 0 || pim > 0 || plus > 0 || minus > 0 || ppGoals > 0 || shGoals > 0
    }
}

struct PlayerStatsDetailView: View {
    let player: Player
    let team: Team

    private var seasonGamesPlayed: Int {
        team.games.filter { game in
            game.events.contains {
                $0.primaryPlayer?.persistentModelID == player.persistentModelID ||
                $0.secondaryPlayer?.persistentModelID == player.persistentModelID ||
                $0.tertiaryPlayer?.persistentModelID == player.persistentModelID
            }
        }.count
    }

    private var seasonGoals: Int {
        team.games.reduce(0) { total, game in
            total + game.events.filter {
                $0.type == .goalFor &&
                $0.primaryPlayer?.persistentModelID == player.persistentModelID
            }.count
        }
    }

    private var seasonAssists: Int {
        team.games.reduce(0) { total, game in
            total + game.events.filter {
                $0.type == .goalFor &&
                (
                    $0.secondaryPlayer?.persistentModelID == player.persistentModelID ||
                    $0.tertiaryPlayer?.persistentModelID == player.persistentModelID
                )
            }.count
        }
    }

    private var seasonShots: Int {
        team.games.reduce(0) { total, game in
            total + game.events.filter {
                $0.type == .shot &&
                $0.primaryPlayer?.persistentModelID == player.persistentModelID
            }.count
        }
    }

    private var seasonPIM: Int {
        team.games.reduce(0) { total, game in
            total + game.events
                .filter {
                    $0.type == .penalty &&
                    $0.primaryPlayer?.persistentModelID == player.persistentModelID
                }
                .compactMap(\.pimMinutes)
                .reduce(0, +)
        }
    }

    private var seasonPlus: Int {
        team.games.reduce(0) { total, game in
            total + game.events.filter {
                $0.type == .plus &&
                $0.primaryPlayer?.persistentModelID == player.persistentModelID
            }.count
        }
    }

    private var seasonMinus: Int {
        team.games.reduce(0) { total, game in
            total + game.events.filter {
                $0.type == .minus &&
                $0.primaryPlayer?.persistentModelID == player.persistentModelID
            }.count
        }
    }

    private var seasonPPGoals: Int {
        team.games.reduce(0) { total, game in
            total + game.events.filter {
                $0.type == .goalFor &&
                $0.strength == .powerPlay &&
                $0.primaryPlayer?.persistentModelID == player.persistentModelID
            }.count
        }
    }

    private var seasonSHGoals: Int {
        team.games.reduce(0) { total, game in
            total + game.events.filter {
                $0.type == .goalFor &&
                $0.strength == .shortHanded &&
                $0.primaryPlayer?.persistentModelID == player.persistentModelID
            }.count
        }
    }

    private var seasonPoints: Int {
        seasonGoals + seasonAssists
    }

    private var seasonPlusMinus: Int {
        seasonPlus - seasonMinus
    }

    private var gameStats: [PlayerGameStatLine] {
        team.games
            .sorted { $0.date > $1.date }
            .map { game in
                let goals = game.events.filter {
                    $0.type == .goalFor &&
                    $0.primaryPlayer?.persistentModelID == player.persistentModelID
                }.count

                let assists = game.events.filter {
                    $0.type == .goalFor &&
                    (
                        $0.secondaryPlayer?.persistentModelID == player.persistentModelID ||
                        $0.tertiaryPlayer?.persistentModelID == player.persistentModelID
                    )
                }.count

                let shots = game.events.filter {
                    $0.type == .shot &&
                    $0.primaryPlayer?.persistentModelID == player.persistentModelID
                }.count

                let pim = game.events
                    .filter {
                        $0.type == .penalty &&
                        $0.primaryPlayer?.persistentModelID == player.persistentModelID
                    }
                    .compactMap(\.pimMinutes)
                    .reduce(0, +)

                let plus = game.events.filter {
                    $0.type == .plus &&
                    $0.primaryPlayer?.persistentModelID == player.persistentModelID
                }.count

                let minus = game.events.filter {
                    $0.type == .minus &&
                    $0.primaryPlayer?.persistentModelID == player.persistentModelID
                }.count

                let ppGoals = game.events.filter {
                    $0.type == .goalFor &&
                    $0.strength == .powerPlay &&
                    $0.primaryPlayer?.persistentModelID == player.persistentModelID
                }.count

                let shGoals = game.events.filter {
                    $0.type == .goalFor &&
                    $0.strength == .shortHanded &&
                    $0.primaryPlayer?.persistentModelID == player.persistentModelID
                }.count

                return PlayerGameStatLine(
                    game: game,
                    goals: goals,
                    assists: assists,
                    shots: shots,
                    pim: pim,
                    plus: plus,
                    minus: minus,
                    ppGoals: ppGoals,
                    shGoals: shGoals
                )
            }
            .filter(\.hasStats)
    }

    private var playerNotes: [(game: Game, event: GameEvent)] {
        team.games
            .sorted { $0.date > $1.date }
            .flatMap { game in
                game.events
                    .filter {
                        $0.type == .note &&
                        $0.primaryPlayer?.persistentModelID == player.persistentModelID
                    }
                    .sorted { $0.timestamp > $1.timestamp }
                    .map { (game: game, event: $0) }
            }
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("#\(player.number) \(player.name)")
                        .font(.title3)
                        .fontWeight(.bold)

                    Text(player.position.label)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Season Totals") {
                statRow("Games Played", "\(seasonGamesPlayed)")
                statRow("Goals", "\(seasonGoals)")
                statRow("Assists", "\(seasonAssists)")
                statRow("Points", "\(seasonPoints)")
                statRow("Shots", "\(seasonShots)")
                statRow("PIM", "\(seasonPIM)")
                statRow("Plus", "\(seasonPlus)")
                statRow("Minus", "\(seasonMinus)")
                statRow("Plus/Minus", "\(seasonPlusMinus)")
                statRow("PP Goals", "\(seasonPPGoals)")
                statRow("SH Goals", "\(seasonSHGoals)")
            }

            Section("Game Breakdown") {
                if gameStats.isEmpty {
                    Text("No game stats yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(gameStats) { stat in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("vs \(stat.game.opponent)")
                                    .font(.headline)
                                Spacer()
                                Text(stat.game.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            HStack(spacing: 12) {
                                Text("G \(stat.goals)")
                                Text("A \(stat.assists)")
                                Text("P \(stat.points)")
                                Text("S \(stat.shots)")
                                Text("PIM \(stat.pim)")
                                Text("+/- \(stat.plusMinus)")
                            }
                            .font(.subheadline)

                            HStack(spacing: 12) {
                                Text("PPG \(stat.ppGoals)")
                                Text("SHG \(stat.shGoals)")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }

            Section("Notes") {
                if playerNotes.isEmpty {
                    Text("No notes for this player")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(playerNotes.enumerated()), id: \.offset) { _, item in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("vs \(item.game.opponent)")
                                    .font(.headline)
                                Spacer()
                                Text(item.event.timestamp.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            if let note = item.event.noteText, !note.isEmpty {
                                Text(note)
                            } else {
                                Text("No note text")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .navigationTitle("Player Stats")
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
