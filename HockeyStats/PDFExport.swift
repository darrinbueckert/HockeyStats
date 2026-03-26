import Foundation
import UIKit
import SwiftData

enum PDFExport {
    static func makeGameReportPDF(for game: Game) -> URL? {
        let teamName = game.team?.name ?? "Team"
        let fileName = "\(safeFileName(teamName))_vs_\(safeFileName(game.opponent))_Game_Report.pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        let data = NSMutableData()
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let margin: CGFloat = 36
        let contentWidth = pageRect.width - (margin * 2)

        UIGraphicsBeginPDFContextToData(data, pageRect, nil)
        UIGraphicsBeginPDFPage()

        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndPDFContext()
            return nil
        }

        var y: CGFloat = margin

        func beginPage() {
            UIGraphicsBeginPDFPage()
            context.setFillColor(UIColor.white.cgColor)
            context.fill(pageRect)
            y = margin
        }

        context.setFillColor(UIColor.white.cgColor)
        context.fill(pageRect)

        func ensureSpace(_ needed: CGFloat) {
            if y + needed > pageRect.height - margin {
                beginPage()
            }
        }

        func drawText(_ text: String, font: UIFont, indent: CGFloat = 0) {
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.black
            ]

            let drawWidth = contentWidth - indent
            let rect = NSString(string: text).boundingRect(
                with: CGSize(width: drawWidth, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: attributes,
                context: nil
            )

            ensureSpace(ceil(rect.height) + 8)

            NSString(string: text).draw(
                in: CGRect(x: margin + indent, y: y, width: drawWidth, height: ceil(rect.height)),
                withAttributes: attributes
            )

            y += ceil(rect.height) + 6
        }

        func drawDivider() {
            ensureSpace(12)
            context.setStrokeColor(UIColor.lightGray.cgColor)
            context.setLineWidth(1)
            context.move(to: CGPoint(x: margin, y: y))
            context.addLine(to: CGPoint(x: pageRect.width - margin, y: y))
            context.strokePath()
            y += 10
        }

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

        let goalieName = game.goalie.map { "#\($0.number) \($0.name)" } ?? "None selected"
        let saves = max(shotsAgainstUsed - goalsAgainst, 0)
        let savePct: String = {
            guard shotsAgainstUsed > 0 else { return ".000" }
            return String(format: "%.3f", Double(saves) / Double(shotsAgainstUsed))
        }()

        drawText("Game Report", font: .boldSystemFont(ofSize: 22))
        drawText("\(game.team?.name ?? "Team") vs \(game.opponent)", font: .systemFont(ofSize: 15))
        drawText("Date: \(game.date.formatted(date: .abbreviated, time: .shortened))", font: .systemFont(ofSize: 12))
        drawText("Generated: \(Date().formatted(date: .abbreviated, time: .shortened))", font: .systemFont(ofSize: 12))
        drawDivider()

        drawText("Summary", font: .boldSystemFont(ofSize: 16))
        drawText("GF: \(goalsFor)   GA: \(goalsAgainst)   SF: \(shotsFor)   SA Used: \(shotsAgainstUsed)", font: .systemFont(ofSize: 12))
        drawText("Tracked SA: \(trackedOpponentShots)   PIM: \(totalPIM)   PPG: \(ppGoals)   SHG: \(shGoals)   SHGA: \(shGoalsAgainst)", font: .systemFont(ofSize: 12))
        drawText("Shootout: \(shootoutFor)-\(shootoutAgainst)", font: .systemFont(ofSize: 12))
        drawDivider()

        drawText("Goalie", font: .boldSystemFont(ofSize: 16))
        drawText("Goalie: \(goalieName)", font: .systemFont(ofSize: 12))
        drawText("SA: \(shotsAgainstUsed)   GA: \(goalsAgainst)   Saves: \(saves)   SV%: \(savePct)", font: .systemFont(ofSize: 12))
        drawDivider()

        drawText("Player Game Stats", font: .boldSystemFont(ofSize: 16))

        let players = (game.team?.players ?? []).sorted {
            if $0.number == $1.number { return $0.name < $1.name }
            return $0.number < $1.number
        }

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

            drawText("#\(player.number) \(player.name) (\(player.position.label))", font: .boldSystemFont(ofSize: 12))
            drawText("G \(goals)  A \(assists)  PTS \(pts)  S \(shots)  PIM \(pim)  +/- \(pm)  PPG \(ppg)  SHG \(shg)", font: .systemFont(ofSize: 12), indent: 10)
        }

        drawDivider()
        drawText("Notes", font: .boldSystemFont(ofSize: 16))

        let notes = game.events
            .filter { $0.type == .note }
            .sorted { $0.timestamp < $1.timestamp }

        if notes.isEmpty {
            drawText("No notes", font: .systemFont(ofSize: 12))
        } else {
            for event in notes {
                let playerText = event.primaryPlayer.map { "#\($0.number) \($0.name)" } ?? "General"
                let line = "\(event.timestamp.formatted(date: .omitted, time: .standard)) | \(periodLabel(for: event.periodNumber)) | \(playerText) | \(event.noteText ?? "")"
                drawText(line, font: .systemFont(ofSize: 12))
            }
        }

        drawDivider()
        drawText("Event Log", font: .boldSystemFont(ofSize: 16))

        let events = game.events.sorted { $0.timestamp < $1.timestamp }

        for event in events {
            let isShootout = event.type == .shootoutAttemptFor || event.type == .shootoutAttemptAgainst
            let line = "\(event.timestamp.formatted(date: .omitted, time: .standard)) | \(periodLabel(for: event.periodNumber, isShootoutEvent: isShootout)) | \(eventTitle(for: event)) | \(eventDetail(for: event))"
            drawText(line, font: .systemFont(ofSize: 11))
        }

        UIGraphicsEndPDFContext()

        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            print("Failed to write game PDF: \(error)")
            return nil
        }
    }

    static func makeSeasonReportPDF(for team: Team) -> URL? {
        let fileName = "\(safeFileName(team.name))_Season_Report.pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        let data = NSMutableData()
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let margin: CGFloat = 36
        let contentWidth = pageRect.width - (margin * 2)

        UIGraphicsBeginPDFContextToData(data, pageRect, nil)
        UIGraphicsBeginPDFPage()

        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndPDFContext()
            return nil
        }

        var y: CGFloat = margin

        func beginPage() {
            UIGraphicsBeginPDFPage()
            context.setFillColor(UIColor.white.cgColor)
            context.fill(pageRect)
            y = margin
        }

        context.setFillColor(UIColor.white.cgColor)
        context.fill(pageRect)

        func ensureSpace(_ needed: CGFloat) {
            if y + needed > pageRect.height - margin {
                beginPage()
            }
        }

        func drawText(_ text: String, font: UIFont, indent: CGFloat = 0) {
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.black
            ]

            let drawWidth = contentWidth - indent
            let rect = NSString(string: text).boundingRect(
                with: CGSize(width: drawWidth, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: attributes,
                context: nil
            )

            ensureSpace(ceil(rect.height) + 8)

            NSString(string: text).draw(
                in: CGRect(x: margin + indent, y: y, width: drawWidth, height: ceil(rect.height)),
                withAttributes: attributes
            )

            y += ceil(rect.height) + 6
        }

        func drawDivider() {
            ensureSpace(12)
            context.setStrokeColor(UIColor.lightGray.cgColor)
            context.setLineWidth(1)
            context.move(to: CGPoint(x: margin, y: y))
            context.addLine(to: CGPoint(x: pageRect.width - margin, y: y))
            context.strokePath()
            y += 10
        }

        drawText("Season Report", font: .boldSystemFont(ofSize: 22))
        drawText(team.name, font: .systemFont(ofSize: 15))
        drawText("Generated: \(Date().formatted(date: .abbreviated, time: .shortened))", font: .systemFont(ofSize: 12))
        drawDivider()

        drawText("Skaters", font: .boldSystemFont(ofSize: 16))

        let skaters = team.players.filter { $0.position != .goalie }.sorted {
            if $0.number == $1.number { return $0.name < $1.name }
            return $0.number < $1.number
        }

        for player in skaters {
            let stats = seasonSkaterStats(for: player, on: team)
            drawText("#\(player.number) \(player.name) (\(player.position.label))", font: .boldSystemFont(ofSize: 12))
            drawText("GP \(stats.gamesPlayed)  G \(stats.goals)  A \(stats.assists)  PTS \(stats.points)  S \(stats.shots)  PIM \(stats.pim)  +/- \(stats.plusMinus)  PPG \(stats.ppGoals)  SHG \(stats.shGoals)", font: .systemFont(ofSize: 12), indent: 10)
        }

        drawDivider()
        drawText("Goalies", font: .boldSystemFont(ofSize: 16))

        let goalies = team.players.filter { $0.position == .goalie }.sorted {
            if $0.number == $1.number { return $0.name < $1.name }
            return $0.number < $1.number
        }

        for player in goalies {
            let stats = seasonGoalieStats(for: player, on: team)
            drawText("#\(player.number) \(player.name) (\(player.position.label))", font: .boldSystemFont(ofSize: 12))
            drawText("GP \(stats.gamesPlayed)  SA \(stats.shotsAgainst)  GA \(stats.goalsAgainst)  Saves \(stats.saves)  SV% \(stats.savePercentageText)", font: .systemFont(ofSize: 12), indent: 10)
        }

        UIGraphicsEndPDFContext()

        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            print("Failed to write season PDF: \(error)")
            return nil
        }
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
            if let player = event.primaryPlayer { parts.append("#\(player.number) \(player.name)") }
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
            total + game.events.filter { $0.type == .goalFor && $0.primaryPlayer?.persistentModelID == player.persistentModelID }.count
        }

        let assists = team.games.reduce(0) { total, game in
            total + game.events.filter {
                $0.type == .goalFor &&
                ($0.secondaryPlayer?.persistentModelID == player.persistentModelID ||
                 $0.tertiaryPlayer?.persistentModelID == player.persistentModelID)
            }.count
        }

        let shots = team.games.reduce(0) { total, game in
            total + game.events.filter { $0.type == .shot && $0.primaryPlayer?.persistentModelID == player.persistentModelID }.count
        }

        let pim = team.games.reduce(0) { total, game in
            total + game.events
                .filter { $0.type == .penalty && $0.primaryPlayer?.persistentModelID == player.persistentModelID }
                .compactMap(\.pimMinutes)
                .reduce(0, +)
        }

        let plus = team.games.reduce(0) { total, game in
            total + game.events.filter { $0.type == .plus && $0.primaryPlayer?.persistentModelID == player.persistentModelID }.count
        }

        let minus = team.games.reduce(0) { total, game in
            total + game.events.filter { $0.type == .minus && $0.primaryPlayer?.persistentModelID == player.persistentModelID }.count
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
