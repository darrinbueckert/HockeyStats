import SwiftUI
import SwiftData

struct SeasonSkaterStats: Identifiable {
    let id = UUID()
    let player: Player
    let gamesPlayed: Int
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
}

struct SeasonGoalieStats: Identifiable {
    let id = UUID()
    let player: Player
    let gamesPlayed: Int
    let shotsAgainst: Int
    let goalsAgainst: Int

    var saves: Int {
        max(shotsAgainst - goalsAgainst, 0)
    }

    var savePercentage: Double {
        guard shotsAgainst > 0 else { return 0 }
        return Double(saves) / Double(shotsAgainst)
    }

    var savePercentageText: String {
        guard shotsAgainst > 0 else { return ".000" }
        return String(format: "%.3f", savePercentage)
    }
}

struct TeamSeasonStatsView: View {
    let team: Team

    private var skaters: [Player] {
        team.players
            .filter { $0.position != .goalie }
            .sorted { lhs, rhs in
                let l = skaterStats(for: lhs)
                let r = skaterStats(for: rhs)

                if l.points == r.points {
                    if l.goals == r.goals {
                        return lhs.number < rhs.number
                    }
                    return l.goals > r.goals
                }
                return l.points > r.points
            }
    }

    private var goalies: [Player] {
        team.players
            .filter { $0.position == .goalie }
            .sorted { lhs, rhs in
                let l = goalieStats(for: lhs)
                let r = goalieStats(for: rhs)

                if l.savePercentage == r.savePercentage {
                    return lhs.number < rhs.number
                }
                return l.savePercentage > r.savePercentage
            }
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text(team.name)
                        .font(.headline)
                    Text("Season Totals")
                        .font(.title3)
                }
            }

            Section("Skaters") {
                if skaters.isEmpty {
                    Text("No skaters")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(skaters) { player in
                        let stats = skaterStats(for: player)

                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("#\(player.number) \(player.name)")
                                    .font(.headline)
                                Spacer()
                                Text("\(stats.points) P")
                                    .foregroundStyle(.secondary)
                            }

                            HStack(spacing: 12) {
                                Text("GP \(stats.gamesPlayed)")
                                Text("G \(stats.goals)")
                                Text("A \(stats.assists)")
                                Text("S \(stats.shots)")
                                Text("PIM \(stats.pim)")
                                Text("+/- \(stats.plusMinus)")
                            }
                            .font(.subheadline)

                            HStack(spacing: 12) {
                                Text("PPG \(stats.ppGoals)")
                                Text("SHG \(stats.shGoals)")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }

            Section("Goalies") {
                if goalies.isEmpty {
                    Text("No goalies")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(goalies) { player in
                        let stats = goalieStats(for: player)

                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("#\(player.number) \(player.name)")
                                    .font(.headline)
                                Spacer()
                                Text(stats.savePercentageText)
                                    .foregroundStyle(.secondary)
                            }

                            HStack(spacing: 12) {
                                Text("GP \(stats.gamesPlayed)")
                                Text("SA \(stats.shotsAgainst)")
                                Text("GA \(stats.goalsAgainst)")
                                Text("SV \(stats.saves)")
                            }
                            .font(.subheadline)

                            HStack(spacing: 12) {
                                Text("SV% \(stats.savePercentageText)")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .navigationTitle("Season Stats")
    }

    private func skaterStats(for player: Player) -> SeasonSkaterStats {
        let gamesPlayed = team.games.filter { game in
            game.events.contains {
                $0.primaryPlayer?.persistentModelID == player.persistentModelID ||
                $0.secondaryPlayer?.persistentModelID == player.persistentModelID ||
                $0.tertiaryPlayer?.persistentModelID == player.persistentModelID
            }
        }.count

        let goals = team.games.reduce(0) { total, game in
            total + game.events.filter {
                $0.type == .goalFor &&
                $0.primaryPlayer?.persistentModelID == player.persistentModelID
            }.count
        }

        let assists = team.games.reduce(0) { total, game in
            total + game.events.filter {
                $0.type == .goalFor &&
                (
                    $0.secondaryPlayer?.persistentModelID == player.persistentModelID ||
                    $0.tertiaryPlayer?.persistentModelID == player.persistentModelID
                )
            }.count
        }

        let shots = team.games.reduce(0) { total, game in
            total + game.events.filter {
                $0.type == .shot &&
                $0.primaryPlayer?.persistentModelID == player.persistentModelID
            }.count
        }

        let pim = team.games.reduce(0) { total, game in
            total + game.events
                .filter {
                    $0.type == .penalty &&
                    $0.primaryPlayer?.persistentModelID == player.persistentModelID
                }
                .compactMap(\.pimMinutes)
                .reduce(0, +)
        }

        let plus = team.games.reduce(0) { total, game in
            total + game.events.filter {
                $0.type == .plus &&
                $0.primaryPlayer?.persistentModelID == player.persistentModelID
            }.count
        }

        let minus = team.games.reduce(0) { total, game in
            total + game.events.filter {
                $0.type == .minus &&
                $0.primaryPlayer?.persistentModelID == player.persistentModelID
            }.count
        }

        let ppGoals = team.games.reduce(0) { total, game in
            total + game.events.filter {
                $0.type == .goalFor &&
                $0.strength == .powerPlay &&
                $0.primaryPlayer?.persistentModelID == player.persistentModelID
            }.count
        }

        let shGoals = team.games.reduce(0) { total, game in
            total + game.events.filter {
                $0.type == .goalFor &&
                $0.strength == .shortHanded &&
                $0.primaryPlayer?.persistentModelID == player.persistentModelID
            }.count
        }

        return SeasonSkaterStats(
            player: player,
            gamesPlayed: gamesPlayed,
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

    private func goalieStats(for player: Player) -> SeasonGoalieStats {
        let goalieGames = team.games.filter {
            $0.goalie?.persistentModelID == player.persistentModelID
        }

        let shotsAgainst = goalieGames.reduce(0) { total, game in
            total + (game.shotsAgainst > 0
                ? game.shotsAgainst
                : game.events.filter { $0.type == .opponentShot }.count)
        }

        let goalsAgainst = goalieGames.reduce(0) { total, game in
            total + game.events.filter { $0.type == .goalAgainst }.count
        }

        return SeasonGoalieStats(
            player: player,
            gamesPlayed: goalieGames.count,
            shotsAgainst: shotsAgainst,
            goalsAgainst: goalsAgainst
        )
    }
}
