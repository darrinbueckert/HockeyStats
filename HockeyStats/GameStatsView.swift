import SwiftUI
import SwiftData

struct GamePlayerStats: Identifiable {
    let id = UUID()
    let player: Player
    let goals: Int
    let assists: Int
    let shots: Int
    let pim: Int
    let plus: Int
    let minus: Int
    let ppGoals: Int
    let shGoals: Int

    var points: Int {
        goals + assists
    }

    var plusMinus: Int {
        plus - minus
    }

    var hasStats: Bool {
        goals > 0 ||
        assists > 0 ||
        shots > 0 ||
        pim > 0 ||
        plus > 0 ||
        minus > 0 ||
        ppGoals > 0 ||
        shGoals > 0
    }
}

struct GameStatsView: View {
    let game: Game

    @State private var exportURL: URL?

    private var sortedPlayers: [Player] {
        (game.team?.players ?? []).sorted {
            if $0.number == $1.number {
                return $0.name < $1.name
            }
            return $0.number < $1.number
        }
    }

    private var playerStats: [GamePlayerStats] {
        sortedPlayers.map { player in
            GamePlayerStats(
                player: player,
                goals: goalCount(for: player),
                assists: assistCount(for: player),
                shots: shotCount(for: player),
                pim: pimCount(for: player),
                plus: plusCount(for: player),
                minus: minusCount(for: player),
                ppGoals: ppGoalCount(for: player),
                shGoals: shGoalCount(for: player)
            )
        }
    }

    private var goalieName: String {
        if let goalie = game.goalie {
            return "#\(goalie.number) \(goalie.name)"
        }
        return "None selected"
    }

    private var shotsAgainstUsed: Int {
        game.shotsAgainst > 0 ? game.shotsAgainst : game.events.filter { $0.type == .opponentShot }.count
    }

    private var goalieSaves: Int {
        max(shotsAgainstUsed - goalsAgainst, 0)
    }

    private var goalieSavePercentageText: String {
        guard shotsAgainstUsed > 0 else { return ".000" }
        let value = Double(goalieSaves) / Double(shotsAgainstUsed)
        return String(format: "%.3f", value)
    }

    private var goalsAgainst: Int {
        game.events.filter { $0.type == .goalAgainst }.count
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text(game.team?.name ?? "Team")
                        .font(.headline)
                    Text("vs \(game.opponent)")
                        .font(.title3)
                    Text(game.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Goalie") {
                HStack {
                    Text("Goalie")
                    Spacer()
                    Text(goalieName)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Shots Against")
                    Spacer()
                    Text("\(shotsAgainstUsed)")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Goals Against")
                    Spacer()
                    Text("\(goalsAgainst)")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Saves")
                    Spacer()
                    Text("\(goalieSaves)")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("SV%")
                    Spacer()
                    Text(goalieSavePercentageText)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Player Stats") {
                if playerStats.filter(\.hasStats).isEmpty {
                    Text("No player stats yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(playerStats) { stat in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("#\(stat.player.number) \(stat.player.name)")
                                    .font(.headline)
                                Spacer()
                                Text("\(stat.points) P")
                                    .foregroundStyle(.secondary)
                            }

                            HStack(spacing: 12) {
                                Text("G \(stat.goals)")
                                Text("A \(stat.assists)")
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
        }
        .navigationTitle("Game Stats")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let exportURL {
                    ShareLink(item: exportURL) {
                        Image(systemName: "square.and.arrow.up")
                    }
                } else {
                    Button {
                        exportURL = CSVExport.makeGameStatsCSV(for: game)
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
    }

    private func goalCount(for player: Player) -> Int {
        game.events.filter {
            $0.type == .goalFor &&
            $0.primaryPlayer?.persistentModelID == player.persistentModelID
        }.count
    }

    private func assistCount(for player: Player) -> Int {
        game.events.filter {
            $0.type == .goalFor &&
            (
                $0.secondaryPlayer?.persistentModelID == player.persistentModelID ||
                $0.tertiaryPlayer?.persistentModelID == player.persistentModelID
            )
        }.count
    }

    private func shotCount(for player: Player) -> Int {
        game.events.filter {
            $0.type == .shot &&
            $0.primaryPlayer?.persistentModelID == player.persistentModelID
        }.count
    }

    private func pimCount(for player: Player) -> Int {
        game.events
            .filter {
                $0.type == .penalty &&
                $0.primaryPlayer?.persistentModelID == player.persistentModelID
            }
            .compactMap(\.pimMinutes)
            .reduce(0, +)
    }

    private func plusCount(for player: Player) -> Int {
        game.events.filter {
            $0.type == .plus &&
            $0.primaryPlayer?.persistentModelID == player.persistentModelID
        }.count
    }

    private func minusCount(for player: Player) -> Int {
        game.events.filter {
            $0.type == .minus &&
            $0.primaryPlayer?.persistentModelID == player.persistentModelID
        }.count
    }

    private func ppGoalCount(for player: Player) -> Int {
        game.events.filter {
            $0.type == .goalFor &&
            $0.strength == .powerPlay &&
            $0.primaryPlayer?.persistentModelID == player.persistentModelID
        }.count
    }

    private func shGoalCount(for player: Player) -> Int {
        game.events.filter {
            $0.type == .goalFor &&
            $0.strength == .shortHanded &&
            $0.primaryPlayer?.persistentModelID == player.persistentModelID
        }.count
    }
}
