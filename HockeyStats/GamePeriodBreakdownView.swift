import SwiftUI

struct PeriodStatRow: Identifiable {
    let id = UUID()
    let label: String
    let teamValue: Int
    let opponentValue: Int
}

struct GamePeriodBreakdownView: View {
    let game: Game

    private var periodNumbers: [Int] {
        let periods = Set(
            game.events
                .compactMap(\.periodNumber)
                .filter { $0 > 0 }
        )

        if periods.isEmpty {
            return [1, 2, 3]
        }

        let maxPeriod = max(periods.max() ?? 3, 3)
        return Array(1...maxPeriod)
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text(game.team?.name ?? "Team")
                        .font(.headline)
                    Text("vs \(game.opponent)")
                        .font(.title3)
                    Text(game.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            ForEach(periodNumbers, id: \.self) { period in
                Section(periodLabel(period)) {
                    statRow(
                        label: "Goals",
                        teamValue: goalsFor(in: period),
                        opponentValue: goalsAgainst(in: period)
                    )

                    statRow(
                        label: "Shots",
                        teamValue: shotsFor(in: period),
                        opponentValue: shotsAgainst(in: period)
                    )

                    statRow(
                        label: "PIM",
                        teamValue: pimFor(in: period),
                        opponentValue: 0
                    )
                }
            }

            Section("Totals") {
                statRow(
                    label: "Goals",
                    teamValue: totalGoalsFor,
                    opponentValue: totalGoalsAgainst
                )

                statRow(
                    label: "Shots",
                    teamValue: totalShotsFor,
                    opponentValue: totalShotsAgainst
                )

                statRow(
                    label: "PIM",
                    teamValue: totalPIM,
                    opponentValue: 0
                )
            }
        }
        .navigationTitle("Period Breakdown")
    }

    @ViewBuilder
    private func statRow(label: String, teamValue: Int, opponentValue: Int) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text("\(teamValue)")
                .frame(minWidth: 30, alignment: .trailing)
            Text("-")
                .foregroundStyle(.secondary)
            Text("\(opponentValue)")
                .frame(minWidth: 30, alignment: .leading)
        }
        .font(.subheadline)
    }

    private func periodLabel(_ period: Int) -> String {
        switch period {
        case 1: return "Period 1"
        case 2: return "Period 2"
        case 3: return "Period 3"
        default: return "OT\(period - 3)"
        }
    }

    private func goalsFor(in period: Int) -> Int {
        game.events.filter {
            $0.type == .goalFor && $0.periodNumber == period
        }.count
    }

    private func goalsAgainst(in period: Int) -> Int {
        game.events.filter {
            $0.type == .goalAgainst && $0.periodNumber == period
        }.count
    }

    private func shotsFor(in period: Int) -> Int {
        game.events.filter {
            $0.type == .shot && $0.periodNumber == period
        }.count
    }

    private func shotsAgainst(in period: Int) -> Int {
        game.events.filter {
            $0.type == .opponentShot && $0.periodNumber == period
        }.count
    }

    private func pimFor(in period: Int) -> Int {
        game.events
            .filter {
                $0.type == .penalty && $0.periodNumber == period
            }
            .compactMap(\.pimMinutes)
            .reduce(0, +)
    }

    private var totalGoalsFor: Int {
        game.events.filter { $0.type == .goalFor }.count
    }

    private var totalGoalsAgainst: Int {
        game.events.filter { $0.type == .goalAgainst }.count
    }

    private var totalShotsFor: Int {
        game.events.filter { $0.type == .shot }.count
    }

    private var totalShotsAgainst: Int {
        game.events.filter { $0.type == .opponentShot }.count
    }

    private var totalPIM: Int {
        game.events
            .filter { $0.type == .penalty }
            .compactMap(\.pimMinutes)
            .reduce(0, +)
    }
}
