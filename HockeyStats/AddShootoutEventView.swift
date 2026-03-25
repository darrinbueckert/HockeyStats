import SwiftUI
import SwiftData

struct AddShootoutEventView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let game: Game
    let isForTeam: Bool

    @State private var selectedPlayerIndex: Int = -1
    @State private var didScore = true

    var body: some View {
        NavigationStack {
            Form {
                if isForTeam {
                    Section("Shooter") {
                        Picker("Player", selection: $selectedPlayerIndex) {
                            Text("Select").tag(-1)
                            ForEach(Array(sortedPlayers.enumerated()), id: \.offset) { index, player in
                                Text("#\(player.number) \(player.name)")
                                    .tag(index)
                            }
                        }
                    }
                }

                Section("Result") {
                    Picker("Outcome", selection: $didScore) {
                        Text("Scored").tag(true)
                        Text("Missed").tag(false)
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle(isForTeam ? "Shootout Attempt" : "Opponent Shootout")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let event = GameEvent(
                            type: isForTeam ? .shootoutAttemptFor : .shootoutAttemptAgainst,
                            game: game,
                            primaryPlayer: isForTeam ? player(at: selectedPlayerIndex) : nil,
                            periodNumber: nil,
                            didScore: didScore
                        )

                        context.insert(event)
                        game.events.append(event)
                        dismiss()
                    }
                    .disabled(isForTeam && selectedPlayerIndex == -1)
                }
            }
        }
    }

    private var sortedPlayers: [Player] {
        (game.team?.players ?? []).sorted {
            if $0.number == $1.number {
                return $0.name < $1.name
            }
            return $0.number < $1.number
        }
    }

    private func player(at index: Int) -> Player? {
        guard index >= 0 && index < sortedPlayers.count else { return nil }
        return sortedPlayers[index]
    }
}
