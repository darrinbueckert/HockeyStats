//
//  GoalStrength+Label.swift
//  HockeyStats
//
//  Created by DarrinB on 2026-03-24.
//

import Foundation

extension GoalStrength {
    var label: String {
        switch self {
        case .even:
            return "Even"
        case .powerPlay:
            return "PP"
        case .shortHanded:
            return "SH"
        }
    }
}
