import Foundation
import SwiftData

@Model
class Game {
    var date: Date
    var opponent: String
    var team: Team?

    @Relationship(deleteRule: .cascade)
    var events: [GameEvent] = []

    init(date: Date = Date(), opponent: String, team: Team? = nil) {
        self.date = date
        self.opponent = opponent
        self.team = team
    }
}
