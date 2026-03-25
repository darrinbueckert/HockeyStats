import Foundation
import SwiftData

enum GameEventType: String, Codable, CaseIterable {
    case goalFor
    case shot
    case penalty
    case plus
    case minus
    case goalAgainst
    case note
    case gameStart
    case gameEnd
    case shootoutAttemptFor
    case shootoutAttemptAgainst
}

enum GoalStrength: String, Codable, CaseIterable {
    case even
    case powerPlay
    case shortHanded
}

@Model
class GameEvent {
    var timestamp: Date
    var typeRaw: String
    var strengthRaw: String?

    var game: Game?

    var primaryPlayer: Player?
    var secondaryPlayer: Player?
    var tertiaryPlayer: Player?

    var pimMinutes: Int?
    var noteText: String?

    var periodNumber: Int?
    var didScore: Bool?

    init(
        timestamp: Date = Date(),
        type: GameEventType,
        strength: GoalStrength? = nil,
        game: Game? = nil,
        primaryPlayer: Player? = nil,
        secondaryPlayer: Player? = nil,
        tertiaryPlayer: Player? = nil,
        pimMinutes: Int? = nil,
        noteText: String? = nil,
        periodNumber: Int? = nil,
        didScore: Bool? = nil
    ) {
        self.timestamp = timestamp
        self.typeRaw = type.rawValue
        self.strengthRaw = strength?.rawValue
        self.game = game
        self.primaryPlayer = primaryPlayer
        self.secondaryPlayer = secondaryPlayer
        self.tertiaryPlayer = tertiaryPlayer
        self.pimMinutes = pimMinutes
        self.noteText = noteText
        self.periodNumber = periodNumber
        self.didScore = didScore
    }

    var type: GameEventType {
        get { GameEventType(rawValue: typeRaw) ?? .note }
        set { typeRaw = newValue.rawValue }
    }

    var strength: GoalStrength? {
        get {
            guard let strengthRaw else { return nil }
            return GoalStrength(rawValue: strengthRaw)
        }
        set {
            strengthRaw = newValue?.rawValue
        }
    }
}
