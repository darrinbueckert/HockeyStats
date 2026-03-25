import SwiftUI
import SwiftData

struct AddShotEventView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let game: Game

    var body: some View {
        NavigationStack {
            List {
                if sortedPlayers.isEmpty {
                    Text("No players available")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sortedPlayers) { player in
                        Button {
                            let event = GameEvent(
                                type: .shot,
                                game: game,
                                primaryPlayer: player,
                                periodNumber: game.currentPeriodNumber
                            )

                            context.insert(event)
                            game.events.append(event)
                            dismiss()
                        } label: {
                            HStack {
                                Text("#\(player.number)")
                                    .bold()
                                Text(player.name)
                                Spacer()
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Shot")
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
}
