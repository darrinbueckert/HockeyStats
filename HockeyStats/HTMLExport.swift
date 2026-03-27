import Foundation
import SwiftData

enum HTMLExport {
    static func makeGameNotesHTML(for game: Game) -> URL? {
        let teamName = game.team?.name ?? "Team"
        let matchup = matchupText(for: game)
        let location = locationText(for: game)
        let fileName = "\(safeFileName(teamName))_\(safeFileName(matchup))_Notes.html"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        let notes = game.events
            .filter { $0.type == .note }
            .sorted { $0.timestamp < $1.timestamp }

        var html = """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Game Notes - \(htmlEscape(matchup))</title>
        <style>
            body {
                font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Arial, sans-serif;
                margin: 24px;
                color: #111827;
                background: #ffffff;
            }
            h1 {
                margin-bottom: 6px;
                font-size: 28px;
            }
            .meta {
                margin-bottom: 20px;
                line-height: 1.7;
            }
            .meta strong {
                display: inline-block;
                min-width: 90px;
            }
            .note-card {
                border: 1px solid #d1d5db;
                border-radius: 12px;
                padding: 14px;
                margin-bottom: 14px;
                background: #f9fafb;
            }
            .note-header {
                display: flex;
                justify-content: space-between;
                align-items: baseline;
                gap: 12px;
                margin-bottom: 8px;
            }
            .note-player {
                font-weight: 700;
                font-size: 16px;
            }
            .note-time {
                color: #6b7280;
                font-size: 12px;
                white-space: nowrap;
            }
            .empty {
                color: #6b7280;
                font-style: italic;
                margin-top: 20px;
            }
            @media print {
                body {
                    margin: 12px;
                }
            }
        </style>
        </head>
        <body>
        <h1>Game Notes</h1>
        <div class="meta">
            <div><strong>Team:</strong> \(htmlEscape(teamName))</div>
            <div><strong>Matchup:</strong> \(htmlEscape(matchup))</div>
            <div><strong>Location:</strong> \(htmlEscape(location))</div>
            <div><strong>Date:</strong> \(htmlEscape(game.date.formatted(date: .abbreviated, time: .shortened)))</div>
            <div><strong>Generated:</strong> \(htmlEscape(Date().formatted(date: .abbreviated, time: .shortened)))</div>
        </div>
        """

        if notes.isEmpty {
            html += """
            <div class="empty">No notes for this game.</div>
            """
        } else {
            for event in notes {
                let playerText = event.primaryPlayer.map { "#\($0.number) \($0.name)" } ?? "General Note"
                let timeText = event.timestamp.formatted(date: .omitted, time: .standard)
                let noteText = event.noteText ?? ""

                html += """
                <div class="note-card">
                    <div class="note-header">
                        <div class="note-player">\(htmlEscape(playerText))</div>
                        <div class="note-time">\(htmlEscape(timeText))</div>
                    </div>
                    <div>\(htmlEscape(noteText))</div>
                </div>
                """
            }
        }

        html += """
        </body>
        </html>
        """

        do {
            try html.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            print("Failed to write game notes HTML: \(error)")
            return nil
        }
    }
    
    static func makeGameReportHTML(for game: Game) -> URL? {
        let teamName = game.team?.name ?? "Team"
        let matchup = matchupText(for: game)
        let location = locationText(for: game)
        let fileName = "\(safeFileName(teamName))_\(safeFileName(matchup))_Game_Report.html"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        let goalsFor = game.events.filter { $0.type == .goalFor }.count
        let goalsAgainst = game.events.filter { $0.type == .goalAgainst }.count
        let shotsFor = game.events.filter { $0.type == .shot }.count
        let trackedOpponentShotsCount = game.events.filter { $0.type == .opponentShot }.count
        let shotsAgainstUsed = game.shotsAgainst > 0 ? game.shotsAgainst : trackedOpponentShotsCount
        let totalPIM = game.events
            .filter { $0.type == .penalty }
            .compactMap(\.pimMinutes)
            .reduce(0, +)
        let ppGoals = game.events.filter { $0.type == .goalFor && $0.strength == .powerPlay }.count
        let shGoals = game.events.filter { $0.type == .goalFor && $0.strength == .shortHanded }.count
        let shGoalsAgainst = game.events.filter { $0.type == .goalAgainst && $0.strength == .shortHanded }.count
        let shootoutFor = game.events.filter { $0.type == .shootoutAttemptFor && $0.didScore == true }.count
        let shootoutAgainst = game.events.filter { $0.type == .shootoutAttemptAgainst && $0.didScore == true }.count

        let players = (game.team?.players ?? []).sorted {
            if $0.number == $1.number { return $0.name < $1.name }
            return $0.number < $1.number
        }

        let goaliePlayers = (game.team?.players ?? [])
            .filter { $0.position == .goalie }
            .sorted {
                if $0.number == $1.number { return $0.name < $1.name }
                return $0.number < $1.number
            }

        let goalieRows: [(name: String, sa: Int, ga: Int, saves: Int, svPct: String)] = goaliePlayers.compactMap { goalie in
            let sa = trackedOpponentShots(for: goalie, in: game)
            let ga = trackedGoalsAgainst(for: goalie, in: game)

            guard sa > 0 || ga > 0 || game.goalie?.persistentModelID == goalie.persistentModelID else {
                return nil
            }

            let saves = max(sa - ga, 0)
            let svPct: String = {
                guard sa > 0 else { return ".000" }
                return String(format: "%.3f", Double(saves) / Double(sa))
            }()

            return (
                name: "#\(goalie.number) \(goalie.name)",
                sa: sa,
                ga: ga,
                saves: saves,
                svPct: svPct
            )
        }

        let notes = game.events
            .filter { $0.type == .note }
            .sorted { $0.timestamp < $1.timestamp }

        let sortedEvents = game.events.sorted { $0.timestamp < $1.timestamp }

        var html = """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Game Report - \(htmlEscape(matchup))</title>
        <style>
            body {
                font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Arial, sans-serif;
                margin: 24px;
                color: #111827;
                background: #ffffff;
            }
            h1 {
                margin-bottom: 6px;
                font-size: 28px;
            }
            h2 {
                margin-top: 28px;
                margin-bottom: 10px;
                padding: 10px 12px;
                background: #f3f4f6;
                border-left: 4px solid #2563eb;
                font-size: 18px;
            }
            .meta {
                margin-bottom: 20px;
                line-height: 1.7;
            }
            .meta strong {
                display: inline-block;
                min-width: 90px;
            }
            table {
                width: 100%;
                border-collapse: collapse;
                margin-bottom: 20px;
            }
            th, td {
                border: 1px solid #d1d5db;
                padding: 8px 10px;
                text-align: left;
                vertical-align: top;
            }
            th {
                background: #f9fafb;
                font-weight: 700;
            }
            .center {
                text-align: center;
            }
            .small {
                color: #4b5563;
            }
            @media print {
                body {
                    margin: 12px;
                }
            }
        </style>
        </head>
        <body>
        <h1>Game Report</h1>
        <div class="meta">
            <div><strong>Team:</strong> \(htmlEscape(teamName))</div>
            <div><strong>Matchup:</strong> \(htmlEscape(matchup))</div>
            <div><strong>Location:</strong> \(htmlEscape(location))</div>
            <div><strong>Date:</strong> \(htmlEscape(game.date.formatted(date: .abbreviated, time: .shortened)))</div>
            <div><strong>Generated:</strong> \(htmlEscape(Date().formatted(date: .abbreviated, time: .shortened)))</div>
        </div>

        <h2>Summary</h2>
        <table>
            <tr>
                <th class="center">GF</th>
                <th class="center">GA</th>
                <th class="center">SF</th>
                <th class="center">SA Used</th>
                <th class="center">Tracked SA</th>
                <th class="center">PIM</th>
                <th class="center">PPG</th>
                <th class="center">SHG</th>
                <th class="center">SHGA</th>
                <th class="center">SO</th>
            </tr>
            <tr>
                <td class="center">\(goalsFor)</td>
                <td class="center">\(goalsAgainst)</td>
                <td class="center">\(shotsFor)</td>
                <td class="center">\(shotsAgainstUsed)</td>
                <td class="center">\(trackedOpponentShotsCount)</td>
                <td class="center">\(totalPIM)</td>
                <td class="center">\(ppGoals)</td>
                <td class="center">\(shGoals)</td>
                <td class="center">\(shGoalsAgainst)</td>
                <td class="center">\(shootoutFor)-\(shootoutAgainst)</td>
            </tr>
        </table>

        <h2>Goalies</h2>
        <table>
            <tr>
                <th>Goalie</th>
                <th class="center">SA</th>
                <th class="center">GA</th>
                <th class="center">Saves</th>
                <th class="center">SV%</th>
            </tr>
        """

        if goalieRows.isEmpty {
            let fallbackName = game.goalie.map { "#\($0.number) \($0.name)" } ?? "None selected"
            let fallbackSaves = max(shotsAgainstUsed - goalsAgainst, 0)
            let fallbackSvPct = shotsAgainstUsed > 0
                ? String(format: "%.3f", Double(fallbackSaves) / Double(shotsAgainstUsed))
                : ".000"

            html += """
            <tr>
                <td>\(htmlEscape(fallbackName))</td>
                <td class="center">\(shotsAgainstUsed)</td>
                <td class="center">\(goalsAgainst)</td>
                <td class="center">\(fallbackSaves)</td>
                <td class="center">\(fallbackSvPct)</td>
            </tr>
            """
        } else {
            for row in goalieRows {
                html += """
                <tr>
                    <td>\(htmlEscape(row.name))</td>
                    <td class="center">\(row.sa)</td>
                    <td class="center">\(row.ga)</td>
                    <td class="center">\(row.saves)</td>
                    <td class="center">\(row.svPct)</td>
                </tr>
                """
            }
        }

        html += """
        </table>

        <h2>Player Game Stats</h2>
        <table>
            <tr>
                <th class="center">#</th>
                <th>Name</th>
                <th>Pos</th>
                <th class="center">G</th>
                <th class="center">A</th>
                <th class="center">PTS</th>
                <th class="center">S</th>
                <th class="center">PIM</th>
                <th class="center">+</th>
                <th class="center">-</th>
                <th class="center">+/-</th>
                <th class="center">PPG</th>
                <th class="center">SHG</th>
            </tr>
        """

        for player in players {
            let goals = game.events.filter {
                $0.type == .goalFor &&
                $0.primaryPlayer?.persistentModelID == player.persistentModelID
            }.count

            let assists = game.events.filter {
                $0.type == .goalFor &&
                ($0.secondaryPlayer?.persistentModelID == player.persistentModelID ||
                 $0.tertiaryPlayer?.persistentModelID == player.persistentModelID)
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

            let pts = goals + assists
            let pm = plus - minus

            html += """
            <tr>
                <td class="center">\(player.number)</td>
                <td>\(htmlEscape(player.name))</td>
                <td>\(htmlEscape(player.position.label))</td>
                <td class="center">\(goals)</td>
                <td class="center">\(assists)</td>
                <td class="center">\(pts)</td>
                <td class="center">\(shots)</td>
                <td class="center">\(pim)</td>
                <td class="center">\(plus)</td>
                <td class="center">\(minus)</td>
                <td class="center">\(pm)</td>
                <td class="center">\(ppg)</td>
                <td class="center">\(shg)</td>
            </tr>
            """
        }

        html += """
        </table>

        <h2>Notes</h2>
        <table>
            <tr>
                <th>Time</th>
                <th>Period</th>
                <th>Player</th>
                <th>Note</th>
            </tr>
        """

        if notes.isEmpty {
            html += """
            <tr>
                <td colspan="4" class="small">No notes</td>
            </tr>
            """
        } else {
            for event in notes {
                let playerText = event.primaryPlayer.map { "#\($0.number) \($0.name)" } ?? "General"
                html += """
                <tr>
                    <td>\(htmlEscape(event.timestamp.formatted(date: .omitted, time: .standard)))</td>
                    <td>\(htmlEscape(periodLabel(for: event.periodNumber)))</td>
                    <td>\(htmlEscape(playerText))</td>
                    <td>\(htmlEscape(event.noteText ?? ""))</td>
                </tr>
                """
            }
        }

        html += """
        </table>

        <h2>Event Log</h2>
        <table>
            <tr>
                <th>Time</th>
                <th>Period</th>
                <th>Event</th>
                <th>Details</th>
            </tr>
        """

        for event in sortedEvents {
            let isShootout = event.type == .shootoutAttemptFor || event.type == .shootoutAttemptAgainst
            html += """
            <tr>
                <td>\(htmlEscape(event.timestamp.formatted(date: .omitted, time: .standard)))</td>
                <td>\(htmlEscape(periodLabel(for: event.periodNumber, isShootoutEvent: isShootout)))</td>
                <td>\(htmlEscape(eventTitle(for: event)))</td>
                <td>\(htmlEscape(eventDetail(for: event)))</td>
            </tr>
            """
        }

        html += """
        </table>
        </body>
        </html>
        """

        do {
            try html.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            print("Failed to write game HTML: \(error)")
            return nil
        }
    }

    static func makeSeasonReportHTML(for team: Team) -> URL? {
        let fileName = "\(safeFileName(team.name))_Season_Report.html"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        let skaters = team.players.filter { $0.position != .goalie }.sorted {
            if $0.number == $1.number { return $0.name < $1.name }
            return $0.number < $1.number
        }

        let goalies = team.players.filter { $0.position == .goalie }.sorted {
            if $0.number == $1.number { return $0.name < $1.name }
            return $0.number < $1.number
        }

        var html = """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Season Report</title>
        <style>
            body {
                font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Arial, sans-serif;
                margin: 24px;
                color: #111827;
                background: #ffffff;
            }
            h1 {
                margin-bottom: 6px;
                font-size: 28px;
            }
            h2 {
                margin-top: 28px;
                margin-bottom: 10px;
                padding: 10px 12px;
                background: #f3f4f6;
                border-left: 4px solid #2563eb;
                font-size: 18px;
            }
            .meta {
                margin-bottom: 20px;
                line-height: 1.7;
            }
            .meta strong {
                display: inline-block;
                min-width: 90px;
            }
            table {
                width: 100%;
                border-collapse: collapse;
                margin-bottom: 20px;
            }
            th, td {
                border: 1px solid #d1d5db;
                padding: 8px 10px;
                text-align: left;
                vertical-align: top;
            }
            th {
                background: #f9fafb;
                font-weight: 700;
            }
            .center {
                text-align: center;
            }
            @media print {
                body {
                    margin: 12px;
                }
            }
        </style>
        </head>
        <body>
        <h1>Season Report</h1>
        <div class="meta">
            <div><strong>Team:</strong> \(htmlEscape(team.name))</div>
            <div><strong>Generated:</strong> \(htmlEscape(Date().formatted(date: .abbreviated, time: .shortened)))</div>
        </div>

        <h2>Skaters</h2>
        <table>
            <tr>
                <th class="center">#</th>
                <th>Name</th>
                <th>Pos</th>
                <th class="center">GP</th>
                <th class="center">G</th>
                <th class="center">A</th>
                <th class="center">PTS</th>
                <th class="center">S</th>
                <th class="center">PIM</th>
                <th class="center">+</th>
                <th class="center">-</th>
                <th class="center">+/-</th>
                <th class="center">PPG</th>
                <th class="center">SHG</th>
            </tr>
        """

        for player in skaters {
            let stats = seasonSkaterStats(for: player, on: team)
            html += """
            <tr>
                <td class="center">\(player.number)</td>
                <td>\(htmlEscape(player.name))</td>
                <td>\(htmlEscape(player.position.label))</td>
                <td class="center">\(stats.gamesPlayed)</td>
                <td class="center">\(stats.goals)</td>
                <td class="center">\(stats.assists)</td>
                <td class="center">\(stats.points)</td>
                <td class="center">\(stats.shots)</td>
                <td class="center">\(stats.pim)</td>
                <td class="center">\(stats.plus)</td>
                <td class="center">\(stats.minus)</td>
                <td class="center">\(stats.plusMinus)</td>
                <td class="center">\(stats.ppGoals)</td>
                <td class="center">\(stats.shGoals)</td>
            </tr>
            """
        }

        html += """
        </table>

        <h2>Goalies</h2>
        <table>
            <tr>
                <th class="center">#</th>
                <th>Name</th>
                <th>Pos</th>
                <th class="center">GP</th>
                <th class="center">SA</th>
                <th class="center">GA</th>
                <th class="center">Saves</th>
                <th class="center">SV%</th>
            </tr>
        """

        for player in goalies {
            let stats = seasonGoalieStats(for: player, on: team)
            html += """
            <tr>
                <td class="center">\(player.number)</td>
                <td>\(htmlEscape(player.name))</td>
                <td>\(htmlEscape(player.position.label))</td>
                <td class="center">\(stats.gamesPlayed)</td>
                <td class="center">\(stats.shotsAgainst)</td>
                <td class="center">\(stats.goalsAgainst)</td>
                <td class="center">\(stats.saves)</td>
                <td class="center">\(stats.savePercentageText)</td>
            </tr>
            """
        }

        html += """
        </table>
        </body>
        </html>
        """

        do {
            try html.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            print("Failed to write season HTML: \(error)")
            return nil
        }
    }

    private static func htmlEscape(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }

    private static func safeFileName(_ value: String) -> String {
        value
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: "\\", with: "-")
            .replacingOccurrences(of: ":", with: "-")
    }

    private static func matchupText(for game: Game) -> String {
        game.isHomeGame ? "vs \(game.opponent)" : "@ \(game.opponent)"
    }

    private static func locationText(for game: Game) -> String {
        game.isHomeGame ? "Home" : "Away"
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

    private static func activeGoalie(at timestamp: Date, for game: Game) -> Player? {
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

    private static func trackedOpponentShots(for goalie: Player, in game: Game) -> Int {
        game.events.filter {
            $0.type == .opponentShot &&
            activeGoalie(at: $0.timestamp, for: game)?.persistentModelID == goalie.persistentModelID
        }.count
    }

    private static func trackedGoalsAgainst(for goalie: Player, in game: Game) -> Int {
        game.events.filter {
            $0.type == .goalAgainst &&
            activeGoalie(at: $0.timestamp, for: game)?.persistentModelID == goalie.persistentModelID
        }.count
    }

    private static func eventTitle(for event: GameEvent) -> String {
        switch event.type {
        case .goalFor: return "Goal"
        case .shot: return "Shot"
        case .opponentShot: return "Opponent Shot"
        case .penalty: return "Penalty"
        case .plus: return "Plus"
        case .minus: return "Minus"
        case .goalAgainst: return "Opponent Goal"
        case .note: return "Note"
        case .gameStart: return "Game Start"
        case .gameEnd: return "Game End"
        case .shootoutAttemptFor: return "Shootout Attempt"
        case .shootoutAttemptAgainst: return "Opponent Shootout Attempt"
        case .goalieChange:
            if event.primaryPlayer == nil {
                return "Goalie Pulled"
            }

            let hasEarlierGoalieEvent = event.game?.events.contains {
                $0.type == .goalieChange && $0.timestamp < event.timestamp
            } ?? false
            return hasEarlierGoalieEvent ? "Goalie Change" : "Starting Goalie"
        }
    }

    private static func eventDetail(for event: GameEvent) -> String {
        switch event.type {
        case .goalFor:
            var parts: [String] = []
            if let scorer = event.primaryPlayer { parts.append("Scorer: #\(scorer.number) \(scorer.name)") }
            if let assist1 = event.secondaryPlayer { parts.append("A1: #\(assist1.number) \(assist1.name)") }
            if let assist2 = event.tertiaryPlayer { parts.append("A2: #\(assist2.number) \(assist2.name)") }
            if let strength = event.strength { parts.append("Strength: \(strength.rawValue)") }
            return parts.joined(separator: " • ")
        case .shot:
            return event.primaryPlayer.map { "#\($0.number) \($0.name)" } ?? ""
        case .opponentShot:
            return ""
        case .penalty:
            var parts: [String] = []
            if let player = event.primaryPlayer { parts.append("#\(player.number) \(player.name)") }
            if let mins = event.pimMinutes { parts.append("\(mins) min") }
            if let note = event.noteText, !note.isEmpty { parts.append(note) }
            return parts.joined(separator: " • ")
        case .plus, .minus:
            return event.primaryPlayer.map { "#\($0.number) \($0.name)" } ?? ""
        case .goalAgainst:
            var parts: [String] = []
            if let strength = event.strength { parts.append("Strength: \(strength.rawValue)") }
            if let note = event.noteText, !note.isEmpty { parts.append(note) }
            return parts.joined(separator: " • ")
        case .note:
            var parts: [String] = []
            if let player = event.primaryPlayer { parts.append("#\(player.number) \(player.name)") }
            if let note = event.noteText, !note.isEmpty { parts.append(note) }
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
        case .goalieChange:
            if let goalie = event.primaryPlayer {
                return "#\(goalie.number) \(goalie.name)"
            }
            return ""
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
                ($0.secondaryPlayer?.persistentModelID == player.persistentModelID ||
                 $0.tertiaryPlayer?.persistentModelID == player.persistentModelID)
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
        let goalieGames = team.games.filter { $0.goalie?.persistentModelID == player.persistentModelID }

        let shotsAgainst = goalieGames.reduce(0) { total, game in
            total + (game.shotsAgainst > 0 ? game.shotsAgainst : game.events.filter { $0.type == .opponentShot }.count)
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
