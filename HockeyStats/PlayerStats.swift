import Foundation
import SwiftData

struct PlayerGameStats: Identifiable {
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

    var points: Int {
        goals + assists
    }

    var plusMinus: Int {
        plus - minus
    }
}

struct PlayerSeasonStats {
    let gamesPlayed: Int
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
}

enum StatsCalculator {
    static func seasonStats(for player: Player, on team: Team) -> PlayerSeasonStats {
        let games = team.games

        let playedGames = games.filter { game in
            didPlayerAppearInGame(player, game: game)
        }

        let goals = games.reduce(0) { $0 + goalCount(for: player, in: $1) }
        let assists = games.reduce(0) { $0 + assistCount(for: player, in: $1) }
        let shots = games.reduce(0) { $0 + shotCount(for: player, in: $1) }
        let pim = games.reduce(0) { $0 + pimCount(for: player, in: $1) }
        let plus = games.reduce(0) { $0 + plusCount(for: player, in: $1) }
        let minus = games.reduce(0) { $0 + minusCount(for: player, in: $1) }
        let ppGoals = games.reduce(0) { $0 + ppGoalCount(for: player, in: $1) }
        let shGoals = games.reduce(0) { $0 + shGoalCount(for: player, in: $1) }

        return PlayerSeasonStats(
            gamesPlayed: playedGames.count,
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

    static func gameStats(for player: Player, on team: Team) -> [PlayerGameStats] {
        team.games
            .sorted { $0.date > $1.date }
            .map { game in
                PlayerGameStats(
                    game: game,
                    goals: goalCount(for: player, in: game),
                    assists: assistCount(for: player, in: game),
                    shots: shotCount(for: player, in: game),
                    pim: pimCount(for: player, in: game),
                    plus: plusCount(for: player, in: game),
                    minus: minusCount(for: player, in: game),
                    ppGoals: ppGoalCount(for: player, in: game),
                    shGoals: shGoalCount(for: player, in: game)
                )
            }
            .filter {
                $0.goals > 0 ||
                $0.assists > 0 ||
                $0.shots > 0 ||
                $0.pim > 0 ||
                $0.plus > 0 ||
                $0.minus > 0 ||
                $0.ppGoals > 0 ||
                $0.shGoals > 0
            }
    }

    static func notes(for player: Player, on team: Team) -> [(game: Game, event: GameEvent)] {
        team.games.flatMap { game in
            game.events
                .filter {
                    $0.type == .note &&
                    $0.primaryPlayer?.persistentModelID == player.persistentModelID
                }
                .map { (game: game, event: $0) }
        }
        .sorted { $0.event.timestamp > $1.event.timestamp }
    }

    private static func didPlayerAppearInGame(_ player: Player, game: Game) -> Bool {
        game.events.contains {
            $0.primaryPlayer?.persistentModelID == player.persistentModelID ||
            $0.secondaryPlayer?.persistentModelID == player.persistentModelID ||
            $0.tertiaryPlayer?.persistentModelID == player.persistentModelID
        }
    }

    private static func goalCount(for player: Player, in game: Game) -> Int {
        game.events.filter {
            $0.type == .goalFor &&
            $0.primaryPlayer?.persistentModelID == player.persistentModelID
        }.count
    }

    private static func assistCount(for player: Player, in game: Game) -> Int {
        game.events.filter {
            $0.type == .goalFor &&
            (
                $0.secondaryPlayer?.persistentModelID == player.persistentModelID ||
                $0.tertiaryPlayer?.persistentModelID == player.persistentModelID
            )
        }.count
    }

    private static func shotCount(for player: Player, in game: Game) -> Int {
        game.events.filter {
            $0.type == .shot &&
            $0.primaryPlayer?.persistentModelID == player.persistentModelID
        }.count
    }

    private static func pimCount(for player: Player, in game: Game) -> Int {
        game.events
            .filter {
                $0.type == .penalty &&
                $0.primaryPlayer?.persistentModelID == player.persistentModelID
            }
            .compactMap(\.pimMinutes)
            .reduce(0, +)
    }

    private static func plusCount(for player: Player, in game: Game) -> Int {
        game.events.filter {
            $0.type == .plus &&
            $0.primaryPlayer?.persistentModelID == player.persistentModelID
        }.count
    }

    private static func minusCount(for player: Player, in game: Game) -> Int {
        game.events.filter {
            $0.type == .minus &&
            $0.primaryPlayer?.persistentModelID == player.persistentModelID
        }.count
    }

    private static func ppGoalCount(for player: Player, in game: Game) -> Int {
        game.events.filter {
            $0.type == .goalFor &&
            $0.strength == .powerPlay &&
            $0.primaryPlayer?.persistentModelID == player.persistentModelID
        }.count
    }

    private static func shGoalCount(for player: Player, in game: Game) -> Int {
        game.events.filter {
            $0.type == .goalFor &&
            $0.strength == .shortHanded &&
            $0.primaryPlayer?.persistentModelID == player.persistentModelID
        }.count
    }
}
