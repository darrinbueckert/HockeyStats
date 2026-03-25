import Foundation
import SwiftData

@Model
class Team {
    var name: String

    @Relationship(deleteRule: .cascade)
    var players: [Player] = []

    @Relationship(deleteRule: .cascade)
    var games: [Game] = []

    init(name: String) {
        self.name = name
    }
}
