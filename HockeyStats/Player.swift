//
//  Player.swift
//  HockeyStats
//
//  Created by DarrinB on 2026-03-24.
//

import Foundation
import SwiftData

@Model
class Player {
    var name: String
    var number: Int
    var team: Team?

    init(name: String, number: Int, team: Team? = nil) {
        self.name = name
        self.number = number
        self.team = team
    }
}
