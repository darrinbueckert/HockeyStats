import Foundation
import SwiftData

enum BackupManager {
    static func makeBackup(from teams: [Team]) throws -> Data {
        let backupTeams = teams.map { team -> BackupTeam in
            let playerIDs: [ObjectIdentifier: String] = Dictionary(
                uniqueKeysWithValues: team.players.map { player in
                    (ObjectIdentifier(player), UUID().uuidString)
                }
            )

            let backupPlayers = team.players.map { player in
                BackupPlayer(
                    id: playerIDs[ObjectIdentifier(player)] ?? UUID().uuidString,
                    name: player.name,
                    number: player.number,
                    positionRaw: player.positionRaw
                )
            }

            let backupGames = team.games.map { game in
                let backupEvents = game.events.map { event in
                    BackupGameEvent(
                        id: UUID().uuidString,
                        timestamp: event.timestamp,
                        typeRaw: event.typeRaw,
                        strengthRaw: event.strengthRaw,
                        primaryPlayerID: event.primaryPlayer.flatMap { playerIDs[ObjectIdentifier($0)] },
                        secondaryPlayerID: event.secondaryPlayer.flatMap { playerIDs[ObjectIdentifier($0)] },
                        tertiaryPlayerID: event.tertiaryPlayer.flatMap { playerIDs[ObjectIdentifier($0)] },
                        pimMinutes: event.pimMinutes,
                        noteText: event.noteText,
                        periodNumber: event.periodNumber,
                        didScore: event.didScore,
                        groupID: event.groupID
                    )
                }

                return BackupGame(
                    id: UUID().uuidString,
                    date: game.date,
                    opponent: game.opponent,
                    currentPeriodNumber: game.currentPeriodNumber,
                    isGameStarted: game.isGameStarted,
                    isGameEnded: game.isGameEnded,
                    isShootout: game.isShootout,
                    shotsAgainst: game.shotsAgainst,
                    teamScore: game.teamScore,
                    opponentScore: game.opponentScore,
                    goaliePlayerID: game.goalie.flatMap { playerIDs[ObjectIdentifier($0)] },
                    events: backupEvents
                )
            }

            return BackupTeam(
                id: UUID().uuidString,
                name: team.name,
                logoData: team.logoData,
                players: backupPlayers,
                games: backupGames
            )
        }

        let backup = AppBackup(
            exportDate: Date(),
            teams: backupTeams
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(backup)
    }

    static func importBackup(from data: Data, into context: ModelContext) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let backup = try decoder.decode(AppBackup.self, from: data)

        for backupTeam in backup.teams {
            let team = Team(
                name: backupTeam.name,
                logoData: backupTeam.logoData
            )
            context.insert(team)

            var playerMap: [String: Player] = [:]

            for backupPlayer in backupTeam.players {
                let position = PlayerPosition(rawValue: backupPlayer.positionRaw) ?? .unknown
                let player = Player(
                    name: backupPlayer.name,
                    number: backupPlayer.number,
                    team: team,
                    position: position
                )
                context.insert(player)
                team.players.append(player)
                playerMap[backupPlayer.id] = player
            }

            for backupGame in backupTeam.games {
                let game = Game(
                    date: backupGame.date,
                    opponent: backupGame.opponent,
                    team: team,
                    teamScore: backupGame.teamScore,
                    opponentScore: backupGame.opponentScore
                )

                game.currentPeriodNumber = backupGame.currentPeriodNumber
                game.isGameStarted = backupGame.isGameStarted
                game.isGameEnded = backupGame.isGameEnded
                game.isShootout = backupGame.isShootout
                game.shotsAgainst = backupGame.shotsAgainst

                if let goalieID = backupGame.goaliePlayerID {
                    game.goalie = playerMap[goalieID]
                }

                context.insert(game)
                team.games.append(game)

                for backupEvent in backupGame.events {
                    let type = GameEventType(rawValue: backupEvent.typeRaw) ?? .note
                    let strength = backupEvent.strengthRaw.flatMap { GoalStrength(rawValue: $0) }

                    let event = GameEvent(
                        timestamp: backupEvent.timestamp,
                        type: type,
                        strength: strength,
                        game: game,
                        primaryPlayer: backupEvent.primaryPlayerID.flatMap { playerMap[$0] },
                        secondaryPlayer: backupEvent.secondaryPlayerID.flatMap { playerMap[$0] },
                        tertiaryPlayer: backupEvent.tertiaryPlayerID.flatMap { playerMap[$0] },
                        pimMinutes: backupEvent.pimMinutes,
                        noteText: backupEvent.noteText,
                        periodNumber: backupEvent.periodNumber,
                        didScore: backupEvent.didScore,
                        groupID: backupEvent.groupID
                    )

                    context.insert(event)
                    game.events.append(event)
                }
            }
        }

        try context.save()
    }
}
