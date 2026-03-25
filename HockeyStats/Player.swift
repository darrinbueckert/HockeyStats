import Foundation
import SwiftData

enum PlayerPosition: String, Codable, CaseIterable {
    case unknown
    case forward
    case defense
    case goalie

    var label: String {
        switch self {
        case .unknown: return "Unknown"
        case .forward: return "Forward"
        case .defense: return "Defense"
        case .goalie: return "Goalie"
        }
    }

    var shortLabel: String {
        switch self {
        case .unknown: return "-"
        case .forward: return "F"
        case .defense: return "D"
        case .goalie: return "G"
        }
    }
}

@Model
class Player {
    var name: String
    var number: Int
    var team: Team?

    var positionRaw: String

    init(name: String, number: Int, team: Team? = nil, position: PlayerPosition = .unknown) {
        self.name = name
        self.number = number
        self.team = team
        self.positionRaw = position.rawValue
    }

    var position: PlayerPosition {
        get { PlayerPosition(rawValue: positionRaw) ?? .unknown }
        set { positionRaw = newValue.rawValue }
    }
}
