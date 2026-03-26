import Foundation
import SwiftData

@Model
class Team {
    var name: String
    var logoData: Data?

    @Relationship(deleteRule: .cascade)
    var players: [Player] = []

    @Relationship(deleteRule: .cascade)
    var games: [Game] = []

    init(name: String, logoData: Data? = nil) {
        self.name = name
        self.logoData = logoData
    }
}
