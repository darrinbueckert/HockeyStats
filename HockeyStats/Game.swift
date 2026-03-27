import Foundation
import SwiftData

@Model
class Game {
    var date: Date
    var opponent: String
    var isHomeGame: Bool
    var team: Team?

    @Relationship(deleteRule: .cascade)
    var events: [GameEvent] = []

    var currentPeriodNumber: Int?
    var isGameStarted: Bool
    var isGameEnded: Bool
    var isShootout: Bool
    var goalie: Player?
    var shotsAgainst: Int

    var teamScore: Int?
    var opponentScore: Int?

    init(
        date: Date = Date(),
        opponent: String,
        isHomeGame: Bool = true,
        team: Team? = nil,
        teamScore: Int? = nil,
        opponentScore: Int? = nil
    ) {
        self.date = date
        self.opponent = opponent
        self.isHomeGame = isHomeGame
        self.team = team
        self.currentPeriodNumber = nil
        self.isGameStarted = false
        self.isGameEnded = false
        self.isShootout = false
        self.goalie = nil
        self.shotsAgainst = 0
        self.teamScore = teamScore
        self.opponentScore = opponentScore
    }
}
