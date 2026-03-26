import SwiftUI

struct TeamStatsView: View {
    let team: Team

    var body: some View {
        TeamSeasonStatsView(team: team)
    }
}
