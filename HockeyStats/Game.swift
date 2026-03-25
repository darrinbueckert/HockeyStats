import Foundation
import SwiftData

@Model
class Game {
    var date: Date
    var opponent: String
    var team: Team?

    @Relationship(deleteRule: .cascade)
    var events: [GameEvent] = []

    var currentPeriodNumber: Int?
    var isGameStarted: Bool
    var isGameEnded: Bool
    var isShootout: Bool

    var goalie: Player?
    var shotsAgainst: Int

    init(date: Date = Date(), opponent: String, team: Team? = nil) {
        self.date = date
        self.opponent = opponent
        self.team = team
        self.currentPeriodNumber = nil
        self.isGameStarted = false
        self.isGameEnded = false
        self.isShootout = false
        self.goalie = nil
        self.shotsAgainst = 0
    }
}
