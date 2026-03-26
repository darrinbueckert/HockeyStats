import Foundation

struct AppBackup: Codable {
    var exportDate: Date
    var teams: [BackupTeam]
}

struct BackupTeam: Codable {
    var id: String
    var name: String
    var logoData: Data?
    var players: [BackupPlayer]
    var games: [BackupGame]
}

struct BackupPlayer: Codable {
    var id: String
    var name: String
    var number: Int
    var positionRaw: String
}

struct BackupGame: Codable {
    var id: String
    var date: Date
    var opponent: String
    var currentPeriodNumber: Int?
    var isGameStarted: Bool
    var isGameEnded: Bool
    var isShootout: Bool
    var shotsAgainst: Int
    var teamScore: Int?
    var opponentScore: Int?
    var goaliePlayerID: String?
    var events: [BackupGameEvent]
}

struct BackupGameEvent: Codable {
    var id: String
    var timestamp: Date
    var typeRaw: String
    var strengthRaw: String?
    var primaryPlayerID: String?
    var secondaryPlayerID: String?
    var tertiaryPlayerID: String?
    var pimMinutes: Int?
    var noteText: String?
    var periodNumber: Int?
    var didScore: Bool?
    var groupID: String
}
