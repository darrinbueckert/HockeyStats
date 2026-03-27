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
    var isHomeGame: Bool
    var currentPeriodNumber: Int?
    var isGameStarted: Bool
    var isGameEnded: Bool
    var isShootout: Bool
    var shotsAgainst: Int
    var teamScore: Int?
    var opponentScore: Int?
    var goaliePlayerID: String?
    var events: [BackupGameEvent]

    enum CodingKeys: String, CodingKey {
        case id
        case date
        case opponent
        case isHomeGame
        case currentPeriodNumber
        case isGameStarted
        case isGameEnded
        case isShootout
        case shotsAgainst
        case teamScore
        case opponentScore
        case goaliePlayerID
        case events
    }

    init(
        id: String,
        date: Date,
        opponent: String,
        isHomeGame: Bool,
        currentPeriodNumber: Int?,
        isGameStarted: Bool,
        isGameEnded: Bool,
        isShootout: Bool,
        shotsAgainst: Int,
        teamScore: Int?,
        opponentScore: Int?,
        goaliePlayerID: String?,
        events: [BackupGameEvent]
    ) {
        self.id = id
        self.date = date
        self.opponent = opponent
        self.isHomeGame = isHomeGame
        self.currentPeriodNumber = currentPeriodNumber
        self.isGameStarted = isGameStarted
        self.isGameEnded = isGameEnded
        self.isShootout = isShootout
        self.shotsAgainst = shotsAgainst
        self.teamScore = teamScore
        self.opponentScore = opponentScore
        self.goaliePlayerID = goaliePlayerID
        self.events = events
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        date = try container.decode(Date.self, forKey: .date)
        opponent = try container.decode(String.self, forKey: .opponent)
        isHomeGame = try container.decodeIfPresent(Bool.self, forKey: .isHomeGame) ?? true
        currentPeriodNumber = try container.decodeIfPresent(Int.self, forKey: .currentPeriodNumber)
        isGameStarted = try container.decode(Bool.self, forKey: .isGameStarted)
        isGameEnded = try container.decode(Bool.self, forKey: .isGameEnded)
        isShootout = try container.decode(Bool.self, forKey: .isShootout)
        shotsAgainst = try container.decode(Int.self, forKey: .shotsAgainst)
        teamScore = try container.decodeIfPresent(Int.self, forKey: .teamScore)
        opponentScore = try container.decodeIfPresent(Int.self, forKey: .opponentScore)
        goaliePlayerID = try container.decodeIfPresent(String.self, forKey: .goaliePlayerID)
        events = try container.decode([BackupGameEvent].self, forKey: .events)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(date, forKey: .date)
        try container.encode(opponent, forKey: .opponent)
        try container.encode(isHomeGame, forKey: .isHomeGame)
        try container.encodeIfPresent(currentPeriodNumber, forKey: .currentPeriodNumber)
        try container.encode(isGameStarted, forKey: .isGameStarted)
        try container.encode(isGameEnded, forKey: .isGameEnded)
        try container.encode(isShootout, forKey: .isShootout)
        try container.encode(shotsAgainst, forKey: .shotsAgainst)
        try container.encodeIfPresent(teamScore, forKey: .teamScore)
        try container.encodeIfPresent(opponentScore, forKey: .opponentScore)
        try container.encodeIfPresent(goaliePlayerID, forKey: .goaliePlayerID)
        try container.encode(events, forKey: .events)
    }
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
