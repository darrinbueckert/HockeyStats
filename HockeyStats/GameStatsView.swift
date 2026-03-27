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

struct ScoringSummaryItem: Identifiable {
    let id = UUID()
    let event: GameEvent
    let scorer: Player?
    let assist1: Player?
    let assist2: Player?
    let strength: GoalStrength?
}

struct GameStatsView: View {
    let game: Game

    @State private var htmlDocument: ExportTextDocument?
    @State private var showingHTMLExporter = false

    private var sortedPlayers: [Player] {
        (game.team?.players ?? []).sorted {
            if $0.number == $1.number { return $0.name < $1.name }
            return $0.number < $1.number
        }
    }

    private var playerStats: [GamePlayerStats] {
        sortedPlayers
            .map { player in
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
            .filter(\.hasStats)
            .sorted { lhs, rhs in
                if lhs.points == rhs.points {
                    if lhs.goals == rhs.goals {
                        return lhs.player.number < rhs.player.number
                    }
                    return lhs.goals > rhs.goals
                }
                return lhs.points > rhs.points
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

    private var scoringSummary: [ScoringSummaryItem] {
        game.events
            .filter { $0.type == .goalFor }
            .sorted { $0.timestamp < $1.timestamp }
            .map {
                ScoringSummaryItem(
                    event: $0,
                    scorer: $0.primaryPlayer,
                    assist1: $0.secondaryPlayer,
                    assist2: $0.tertiaryPlayer,
                    strength: $0.strength
                )
            }
    }

    private var noteEvents: [GameEvent] {
        game.events
            .filter { $0.type == .note }
            .sorted { $0.timestamp > $1.timestamp }
    }

    private var goalsFor: Int {
        game.events.filter { $0.type == .goalFor }.count
    }

    private var goalsAgainst: Int {
        game.events.filter { $0.type == .goalAgainst }.count
    }

    private var shotsFor: Int {
        game.events.filter { $0.type == .shot }.count
    }

    private var trackedOpponentShotsCount: Int {
        game.events.filter { $0.type == .opponentShot }.count
    }

    private var shotsAgainstUsed: Int {
        game.shotsAgainst > 0 ? game.shotsAgainst : trackedOpponentShotsCount
    }

    private var totalPIM: Int {
        game.events
            .filter { $0.type == .penalty }
            .compactMap(\.pimMinutes)
            .reduce(0, +)
    }

    private var powerPlayGoals: Int {
        game.events.filter { $0.type == .goalFor && $0.strength == .powerPlay }.count
    }

    private var shortHandedGoals: Int {
        game.events.filter { $0.type == .goalFor && $0.strength == .shortHanded }.count
    }

    private var shootoutForGoals: Int {
        game.events.filter { $0.type == .shootoutAttemptFor && $0.didScore == true }.count
    }

    private var shootoutAgainstGoals: Int {
        game.events.filter { $0.type == .shootoutAttemptAgainst && $0.didScore == true }.count
    }

    private var gameReportFilename: String {
        let teamName = sanitizedFilenamePart(game.team?.name ?? "Team")
        let opponentName = sanitizedFilenamePart(game.opponent)
        let dateText = game.date.formatted(.iso8601.year().month().day())
        return "\(teamName)_vs_\(opponentName)_\(dateText)"
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text(game.team?.name ?? "Team")
                        .font(.headline)

                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(matchupText)
                                .font(.title3)
                                .fontWeight(.semibold)

                            Text(game.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(goalsFor) - \(goalsAgainst)")
                                .font(.title)
                                .fontWeight(.bold)

                            if let badge = resultBadgeText {
                                Text(badge)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(Color(.tertiarySystemGroupedBackground))
                                    )
                            }

                            Text(statusText)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Summary") {
                summaryRow("Shots", "\(shotsFor) - \(shotsAgainstUsed)")
                summaryRow("Tracked Opponent Shots", "\(trackedOpponentShotsCount)")
                summaryRow("PIM", "\(totalPIM)")
                summaryRow("Power-Play Goals", "\(powerPlayGoals)")
                summaryRow("Short-Handed Goals", "\(shortHandedGoals)")
                if game.events.contains(where: { $0.type == .shootoutAttemptFor || $0.type == .shootoutAttemptAgainst }) {
                    summaryRow("Shootout", "\(shootoutForGoals) - \(shootoutAgainstGoals)")
                }
            }

            Section("Scoring Summary") {
                if scoringSummary.isEmpty {
                    Text("No goals recorded")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(scoringSummary) { item in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(item.scorer.map { "#\($0.number) \($0.name)" } ?? "Unknown Scorer")
                                    .font(.headline)

                                Spacer()

                                Text(periodLabel(for: item.event.periodNumber))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            HStack {
                                Text(item.event.timestamp.formatted(date: .omitted, time: .standard))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Spacer()

                                if let strength = item.strength {
                                    Text(strength.label)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            let assists = assistText(assist1: item.assist1, assist2: item.assist2)
                            if !assists.isEmpty {
                                Text(assists)
                                    .font(.subheadline)
                            }
                        }
                        .padding(.vertical, 2)
                    }
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
                if playerStats.isEmpty {
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

            Section("Notes") {
                if noteEvents.isEmpty {
                    Text("No notes for this game")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(noteEvents) { event in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                if let player = event.primaryPlayer {
                                    Text("#\(player.number) \(player.name)")
                                        .font(.headline)
                                } else {
                                    Text("General Note")
                                        .font(.headline)
                                }

                                Spacer()

                                Text(periodLabel(for: event.periodNumber))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Text(event.timestamp.formatted(date: .omitted, time: .standard))
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            if let note = event.noteText, !note.isEmpty {
                                Text(note)
                                    .font(.body)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .navigationTitle("Game Summary")
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

    private var matchupText: String {
        game.isHomeGame ? "vs \(game.opponent)" : "@ \(game.opponent)"
    }

    private var resultBadgeText: String? {
        guard let teamScore = game.teamScore,
              let opponentScore = game.opponentScore else {
            return nil
        }

        if teamScore == opponentScore {
            return "T"
        }

        let win = teamScore > opponentScore

        if game.isShootout {
            return win ? "SOW" : "SOL"
        }

        if let period = game.currentPeriodNumber, period > 3 {
            return win ? "OTW" : "OTL"
        }

        return win ? "W" : "L"
    }

    private var statusText: String {
        if game.isGameEnded { return "Final" }
        if game.isShootout { return "Shootout" }
        if game.isGameStarted { return "In Progress" }
        return "Not Started"
    }

    private func sanitizedFilenamePart(_ text: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: "\\/:*?\"<>|")
        let cleaned = text.components(separatedBy: invalidCharacters).joined(separator: "")
        return cleaned
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "&", with: "and")
    }

    private func summaryRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }

    private func assistText(assist1: Player?, assist2: Player?) -> String {
        var assists: [String] = []

        if let assist1 {
            assists.append("#\(assist1.number) \(assist1.name)")
        }

        if let assist2 {
            assists.append("#\(assist2.number) \(assist2.name)")
        }

        if assists.isEmpty {
            return ""
        }

        return "Assists: " + assists.joined(separator: ", ")
    }

    private func periodLabel(for period: Int?) -> String {
        guard let period else { return "" }
        switch period {
        case 1: return "P1"
        case 2: return "P2"
        case 3: return "P3"
        default: return "OT\(period - 3)"
        }
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
