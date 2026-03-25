import Foundation
import SwiftData

enum CSVExport {
    static func makeSeasonStatsCSV(for team: Team) -> URL? {
        let fileName = "\(safeFileName(team.name))_Season_Stats.csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        var lines: [String] = []

        lines.append("===== SEASON REPORT =====")
        lines.append("Team,\(escaped(team.name))")
        lines.append("Generated,\(escaped(Date().formatted(date: .abbreviated, time: .shortened)))")

        lines.append(contentsOf: section("Skaters"))
        lines.append("Number,Name,Position,GP,G,A,PTS,S,PIM,Plus,Minus,PlusMinus,PPG,SHG")

        let skaters = team.players
            .filter { $0.position != .goalie }
            .sorted { lhs, rhs in
                if lhs.number == rhs.number {
                    return lhs.name < rhs.name
                }
                return lhs.number < rhs.number
            }

        for player in skaters {
            let stats = seasonSkaterStats(for: player, on: team)
            lines.append([
                "\(player.number)",
                escaped(player.name),
                escaped(player.position.label),
                "\(stats.gamesPlayed)",
                "\(stats.goals)",
                "\(stats.assists)",
                "\(stats.points)",
                "\(stats.shots)",
                "\(stats.pim)",
                "\(stats.plus)",
                "\(stats.minus)",
                "\(stats.plusMinus)",
                "\(stats.ppGoals)",
                "\(stats.shGoals)"
            ].joined(separator: ","))
        }

        lines.append(contentsOf: section("Goalies"))
        lines.append("Number,Name,Position,GP,SA,GA,Saves,SV%")

        let goalies = team.players
            .filter { $0.position == .goalie }
            .sorted { lhs, rhs in
                if lhs.number == rhs.number {
                    return lhs.name < rhs.name
                }
                return lhs.number < rhs.number
            }

        for player in goalies {
            let stats = seasonGoalieStats(for: player, on: team)
            lines.append([
                "\(player.number)",
                escaped(player.name),
                escaped(player.position.label),
                "\(stats.gamesPlayed)",
                "\(stats.shotsAgainst)",
                "\(stats.goalsAgainst)",
                "\(stats.saves)",
                stats.savePercentageText
            ].joined(separator: ","))
        }

        let csv = lines.joined(separator: "\n")

        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            print("Failed to write season CSV: \(error)")
            return nil
        }
    }

    static func makeGameStatsCSV(for game: Game) -> URL? {
        let teamName = game.team?.name ?? "Team"
        let fileName = "\(safeFileName(teamName))_vs_\(safeFileName(game.opponent))_Game_Report.csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        var lines: [String] = []

        let goalsFor = game.events.filter { $0.type == .goalFor }.count
        let goalsAgainst = game.events.filter { $0.type == .goalAgainst }.count
        let shotsFor = game.events.filter { $0.type == .shot }.count
        let trackedOpponentShots = game.events.filter { $0.type == .opponentShot }.count
        let shotsAgainstUsed = game.shotsAgainst > 0 ? game.shotsAgainst : trackedOpponentShots
        let totalPIM = game.events
            .filter { $0.type == .penalty }
            .compactMap(\.pimMinutes)
            .reduce(0, +)
        let ppGoals = game.events.filter { $0.type == .goalFor && $0.strength == .powerPlay }.count
        let shGoals = game.events.filter { $0.type == .goalFor && $0.strength == .shortHanded }.count
        let shGoalsAgainst = game.events.filter { $0.type == .goalAgainst && $0.strength == .shortHanded }.count
        let shootoutFor = game.events.filter { $0.type == .shootoutAttemptFor && $0.didScore == true }.count
        let shootoutAgainst = game.events.filter { $0.type == .shootoutAttemptAgainst && $0.didScore == true }.count

        let goalies: [(number: Int, name: String, gamesPlayed: Int, shotsAgainst: Int, goalsAgainst: Int, saves: Int, savePercentageText: String)] = {
            if let goalie = game.goalie {
                let ga = goalsAgainst
                let sa = shotsAgainstUsed
                let sv = max(sa - ga, 0)
                let svPct: String = {
                    guard sa > 0 else { return ".000" }
                    return String(format: "%.3f", Double(sv) / Double(sa))
                }()
                return [(
                    number: goalie.number,
                    name: goalie.name,
                    gamesPlayed: 1,
                    shotsAgainst: sa,
                    goalsAgainst: ga,
                    saves: sv,
                    savePercentageText: svPct
                )]
            }
            return []
        }()

        lines.append("===== GAME REPORT =====")
        lines.append("Team,\(escaped(teamName))")
        lines.append("Opponent,\(escaped(game.opponent))")
        lines.append("Date,\(escaped(game.date.formatted(date: .abbreviated, time: .shortened)))")
        lines.append("Generated,\(escaped(Date().formatted(date: .abbreviated, time: .shortened)))")

        lines.append(contentsOf: section("Summary"))
        lines.append("GF,GA,SF,SA Used,Tracked SA,PIM,PPG,SHG,SHGA,SO")
        lines.append([
            "\(goalsFor)",
            "\(goalsAgainst)",
            "\(shotsFor)",
            "\(shotsAgainstUsed)",
            "\(trackedOpponentShots)",
            "\(totalPIM)",
            "\(ppGoals)",
            "\(shGoals)",
            "\(shGoalsAgainst)",
            escaped("\(shootoutFor)-\(shootoutAgainst)")
        ].joined(separator: ","))

        lines.append(contentsOf: section("Goalies"))
        lines.append("Number,Name,GP,SA,GA,Saves,SV%")

        if goalies.isEmpty {
            lines.append(",,0,0,0,0,.000")
        } else {
            for goalie in goalies {
                lines.append([
                    "\(goalie.number)",
                    escaped(goalie.name),
                    "\(goalie.gamesPlayed)",
                    "\(goalie.shotsAgainst)",
                    "\(goalie.goalsAgainst)",
                    "\(goalie.saves)",
                    goalie.savePercentageText
                ].joined(separator: ","))
            }
        }

        lines.append(contentsOf: section("Player Game Stats"))
        lines.append("Number,Name,Position,G,A,PTS,S,PIM,Plus,Minus,PlusMinus,PPG,SHG")

        let players = (game.team?.players ?? []).sorted { lhs, rhs in
            if lhs.number == rhs.number {
                return lhs.name < rhs.name
            }
            return lhs.number < rhs.number
        }

        for player in players {
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

            let ppg = game.events.filter {
                $0.type == .goalFor &&
                $0.strength == .powerPlay &&
                $0.primaryPlayer?.persistentModelID == player.persistentModelID
            }.count

            let shg = game.events.filter {
                $0.type == .goalFor &&
                $0.strength == .shortHanded &&
                $0.primaryPlayer?.persistentModelID == player.persistentModelID
            }.count

            let points = goals + assists
            let plusMinus = plus - minus

            lines.append([
                "\(player.number)",
                escaped(player.name),
                escaped(player.position.label),
                "\(goals)",
                "\(assists)",
                "\(points)",
                "\(shots)",
                "\(pim)",
                "\(plus)",
                "\(minus)",
                "\(plusMinus)",
                "\(ppg)",
                "\(shg)"
            ].joined(separator: ","))
        }

        lines.append(contentsOf: section("Notes"))
        lines.append("Time,Period,Player,Note")

        let notes = game.events
            .filter { $0.type == .note }
            .sorted { $0.timestamp < $1.timestamp }

        for event in notes {
            let playerText: String = {
                if let player = event.primaryPlayer {
                    return "#\(player.number) \(player.name)"
                }
                return "General"
            }()

            lines.append([
                escaped(event.timestamp.formatted(date: .omitted, time: .standard)),
                escaped(periodLabel(for: event.periodNumber)),
                escaped(playerText),
                escaped(event.noteText ?? "")
            ].joined(separator: ","))
        }

        lines.append(contentsOf: section("Event Log"))
        lines.append("Time,Period,Event,Details")

        let sortedEvents = game.events.sorted { $0.timestamp < $1.timestamp }

        for event in sortedEvents {
            lines.append([
                escaped(event.timestamp.formatted(date: .omitted, time: .standard)),
                escaped(periodLabel(for: event.periodNumber, isShootoutEvent: event.type == .shootoutAttemptFor || event.type == .shootoutAttemptAgainst)),
                escaped(eventTitle(for: event)),
                escaped(eventDetail(for: event))
            ].joined(separator: ","))
        }

        let csv = lines.joined(separator: "\n")

        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            print("Failed to write game CSV: \(error)")
            return nil
        }
    }

    private static func section(_ title: String) -> [String] {
        [
            "",
            "",
            "===== \(title.uppercased()) ====="
        ]
    }

    private static func escaped(_ value: String) -> String {
        "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
    }

    private static func safeFileName(_ value: String) -> String {
        value.replacingOccurrences(of: "/", with: "-")
    }

    private static func periodLabel(for period: Int?, isShootoutEvent: Bool = false) -> String {
        if isShootoutEvent { return "SO" }
        guard let period else { return "" }
        switch period {
        case 1: return "P1"
        case 2: return "P2"
        case 3: return "P3"
        default: return "OT\(period - 3)"
        }
    }

    private static func eventTitle(for event: GameEvent) -> String {
        switch event.type {
        case .goalFor:
            return "Goal"
        case .shot:
            return "Shot"
        case .opponentShot:
            return "Opponent Shot"
        case .penalty:
            return "Penalty"
        case .plus:
            return "Plus"
        case .minus:
            return "Minus"
        case .goalAgainst:
            return "Opponent Goal"
        case .note:
            return "Note"
        case .gameStart:
            return "Game Start"
        case .gameEnd:
            return "Game End"
        case .shootoutAttemptFor:
            return "Shootout Attempt"
        case .shootoutAttemptAgainst:
            return "Opponent Shootout Attempt"
        }
    }

    private static func eventDetail(for event: GameEvent) -> String {
        switch event.type {
        case .goalFor:
            var parts: [String] = []
            if let scorer = event.primaryPlayer {
                parts.append("Scorer: #\(scorer.number) \(scorer.name)")
            }
            if let assist1 = event.secondaryPlayer {
                parts.append("A1: #\(assist1.number) \(assist1.name)")
            }
            if let assist2 = event.tertiaryPlayer {
                parts.append("A2: #\(assist2.number) \(assist2.name)")
            }
            if let strength = event.strength {
                parts.append("Strength: \(strength.rawValue)")
            }
            return parts.joined(separator: " • ")

        case .shot:
            if let player = event.primaryPlayer {
                return "#\(player.number) \(player.name)"
            }
            return ""

        case .opponentShot:
            return ""

        case .penalty:
            var parts: [String] = []
            if let player = event.primaryPlayer {
                parts.append("#\(player.number) \(player.name)")
            }
            if let mins = event.pimMinutes {
                parts.append("\(mins) min")
            }
            if let note = event.noteText, !note.isEmpty {
                parts.append(note)
            }
            return parts.joined(separator: " • ")

        case .plus, .minus:
            if let player = event.primaryPlayer {
                return "#\(player.number) \(player.name)"
            }
            return ""

        case .goalAgainst:
            var parts: [String] = []
            if let strength = event.strength {
                parts.append("Strength: \(strength.rawValue)")
            }
            if let note = event.noteText, !note.isEmpty {
                parts.append(note)
            }
            return parts.joined(separator: " • ")

        case .note:
            var parts: [String] = []
            if let player = event.primaryPlayer {
                parts.append("#\(player.number) \(player.name)")
            }
            if let note = event.noteText, !note.isEmpty {
                parts.append(note)
            }
            return parts.joined(separator: " • ")

        case .gameStart, .gameEnd:
            return ""

        case .shootoutAttemptFor:
            var parts: [String] = []
            if let player = event.primaryPlayer {
                parts.append("#\(player.number) \(player.name)")
            }
            parts.append(event.didScore == true ? "Scored" : "Missed")
            return parts.joined(separator: " • ")

        case .shootoutAttemptAgainst:
            return event.didScore == true ? "Scored" : "Missed"
        }
    }

    private static func seasonSkaterStats(for player: Player, on team: Team) -> SeasonSkaterStats {
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

    private static func seasonGoalieStats(for player: Player, on team: Team) -> SeasonGoalieStats {
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
