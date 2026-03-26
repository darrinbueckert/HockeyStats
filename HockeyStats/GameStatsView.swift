import SwiftUI
import SwiftData
import UniformTypeIdentifiers

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

    var points: Int { goals + assists }
    var plusMinus: Int { plus - minus }

    var hasStats: Bool {
        goals > 0 || assists > 0 || shots > 0 || pim > 0 || plus > 0 || minus > 0 || ppGoals > 0 || shGoals > 0
    }
}

struct GameGoalieStats: Identifiable {
    let id = UUID()
    let goalie: Player
    let shotsAgainst: Int
    let goalsAgainst: Int

    var saves: Int { max(shotsAgainst - goalsAgainst, 0) }

    var savePercentageText: String {
        guard shotsAgainst > 0 else { return ".000" }
        let value = Double(saves) / Double(shotsAgainst)
        return String(format: "%.3f", value)
    }
}

struct GameStatsView: View {
    let game: Game

    @State private var csvDocument: ExportCSVDocument?
    @State private var showingCSVExporter = false
    @State private var htmlDocument: ExportTextDocument?
    @State private var showingHTMLExporter = false

    private var sortedPlayers: [Player] {
        (game.team?.players ?? []).sorted {
            if $0.number == $1.number { return $0.name < $1.name }
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

    private var goaliePlayers: [Player] {
        (game.team?.players ?? [])
            .filter { $0.position == .goalie }
            .sorted {
                if $0.number == $1.number { return $0.name < $1.name }
                return $0.number < $1.number
            }
    }

    private var goalieStats: [GameGoalieStats] {
        goaliePlayers.compactMap { goalie in
            let shotsAgainst = trackedOpponentShots(for: goalie)
            let goalsAgainst = trackedGoalsAgainst(for: goalie)

            guard shotsAgainst > 0 || goalsAgainst > 0 || game.goalie?.persistentModelID == goalie.persistentModelID else {
                return nil
            }

            return GameGoalieStats(
                goalie: goalie,
                shotsAgainst: shotsAgainst,
                goalsAgainst: goalsAgainst
            )
        }
    }

    private var shotsAgainstUsed: Int {
        game.shotsAgainst > 0 ? game.shotsAgainst : game.events.filter { $0.type == .opponentShot }.count
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

            Section("Goalies") {
                if goalieStats.isEmpty {
                    HStack {
                        Text("Goalie")
                        Spacer()
                        Text(game.goalie.map { "#\($0.number) \($0.name)" } ?? "None selected")
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
                        Text("\(max(shotsAgainstUsed - goalsAgainst, 0))")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("SV%")
                        Spacer()
                        let value = shotsAgainstUsed > 0 ? Double(max(shotsAgainstUsed - goalsAgainst, 0)) / Double(shotsAgainstUsed) : 0
                        Text(shotsAgainstUsed > 0 ? String(format: "%.3f", value) : ".000")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    ForEach(goalieStats) { stat in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("#\(stat.goalie.number) \(stat.goalie.name)")
                                    .font(.headline)
                                Spacer()
                                Text("SV% \(stat.savePercentageText)")
                                    .foregroundStyle(.secondary)
                            }

                            HStack(spacing: 12) {
                                Text("SA \(stat.shotsAgainst)")
                                Text("GA \(stat.goalsAgainst)")
                                Text("SV \(stat.saves)")
                            }
                            .font(.subheadline)
                        }
                        .padding(.vertical, 2)
                    }
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
                Menu {
                   Button("Save HTML Report") {
                        if let url = HTMLExport.makeGameReportHTML(for: game),
                           let html = try? String(contentsOf: url, encoding: .utf8) {
                            htmlDocument = ExportTextDocument(text: html)
                            showingHTMLExporter = true
                        }
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .fileExporter(
            isPresented: $showingCSVExporter,
            document: csvDocument,
            contentType: .commaSeparatedText,
            defaultFilename: gameReportFilename
        ) { result in
            switch result {
            case .success(let url):
                print("Saved CSV to: \(url)")
            case .failure(let error):
                print("CSV export failed: \(error.localizedDescription)")
            }
        }
        .fileExporter(
            isPresented: $showingHTMLExporter,
            document: htmlDocument,
            contentType: .html,
            defaultFilename: gameReportFilename
        ) { result in
            switch result {
            case .success(let url):
                print("Saved HTML to: \(url)")
            case .failure(let error):
                print("HTML export failed: \(error.localizedDescription)")
            }
        }
    }

    private var gameReportFilename: String {
        let teamName = sanitizedFilenamePart(game.team?.name ?? "Team")
        let opponentName = sanitizedFilenamePart(game.opponent)
        let dateText = game.date.formatted(.iso8601.year().month().day())
        return "\(teamName)_vs_\(opponentName)_\(dateText)"
    }

    private func sanitizedFilenamePart(_ text: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: "\\/:*?\"<>|")
        let cleaned = text.components(separatedBy: invalidCharacters).joined(separator: "")
        return cleaned
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "&", with: "and")
    }

    private func activeGoalie(at timestamp: Date) -> Player? {
        let sorted = game.events.sorted { $0.timestamp < $1.timestamp }
        var active: Player? = nil

        for event in sorted {
            if event.timestamp > timestamp { break }
            if event.type == .goalieChange {
                active = event.primaryPlayer
            }
        }

        return active
    }

    private func trackedOpponentShots(for goalie: Player) -> Int {
        game.events.filter {
            $0.type == .opponentShot &&
            activeGoalie(at: $0.timestamp)?.persistentModelID == goalie.persistentModelID
        }.count
    }

    private func trackedGoalsAgainst(for goalie: Player) -> Int {
        game.events.filter {
            $0.type == .goalAgainst &&
            activeGoalie(at: $0.timestamp)?.persistentModelID == goalie.persistentModelID
        }.count
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
            ($0.secondaryPlayer?.persistentModelID == player.persistentModelID ||
             $0.tertiaryPlayer?.persistentModelID == player.persistentModelID)
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
