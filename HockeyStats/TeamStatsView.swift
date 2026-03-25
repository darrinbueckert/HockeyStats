import SwiftUI

struct TeamStatsView: View {
    let team: Team

    private var sortedPlayers: [Player] {
        team.players.sorted {
            if $0.number == $1.number {
                return $0.name < $1.name
            }
            return $0.number < $1.number
        }
    }

    var body: some View {
        List {
            ForEach(sortedPlayers) { player in
                let stats = StatsCalculator.seasonStats(for: player, on: team)

                NavigationLink(destination: PlayerStatsDetailView(player: player, team: team)) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("#\(player.number) \(player.name)")
                                .font(.headline)
                            Spacer()
                            Text("\(stats.points) P")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        HStack(spacing: 12) {
                            Text("GP \(stats.gamesPlayed)")
                            Text("G \(stats.goals)")
                            Text("A \(stats.assists)")
                            Text("S \(stats.shots)")
                            Text("PIM \(stats.pim)")
                            Text("+/- \(stats.plusMinus)")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .navigationTitle("Team Stats")
    }
}
