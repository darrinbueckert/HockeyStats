import SwiftUI
import SwiftData

struct AddPlusMinusEventView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let game: Game

    @State private var selectedType: GameEventType = .plus
    @State private var selectedPlayerIDs: Set<PersistentIdentifier> = []

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Type", selection: $selectedType) {
                        Text("Plus").tag(GameEventType.plus)
                        Text("Minus").tag(GameEventType.minus)
                    }
                    .pickerStyle(.segmented)
                }

                Section("Players") {
                    if sortedPlayers.isEmpty {
                        Text("No players available")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(sortedPlayers) { player in
                            Button {
                                toggleSelection(for: player)
                            } label: {
                                HStack {
                                    Text("#\(player.number)")
                                        .bold()
                                    Text(player.name)
                                    Spacer()
                                    if isSelected(player) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.blue)
                                    }
                                }
                            }
                            .foregroundStyle(.primary)
                        }
                    }
                }
            }
            .navigationTitle("Add Plus / Minus")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEvents()
                    }
                    .disabled(selectedPlayerIDs.isEmpty)
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

    private func isSelected(_ player: Player) -> Bool {
        selectedPlayerIDs.contains(player.persistentModelID)
    }

    private func toggleSelection(for player: Player) {
        let id = player.persistentModelID
        if selectedPlayerIDs.contains(id) {
            selectedPlayerIDs.remove(id)
        } else {
            selectedPlayerIDs.insert(id)
        }
    }

    private func saveEvents() {
        let eventTime = Date()
        let currentPeriod = game.currentPeriodNumber
        let groupID = UUID().uuidString

        let selectedPlayers = sortedPlayers.filter { player in
            selectedPlayerIDs.contains(player.persistentModelID)
        }

        for player in selectedPlayers {
            let event = GameEvent(
                timestamp: eventTime,
                type: selectedType,
                game: game,
                primaryPlayer: player,
                periodNumber: currentPeriod,
                groupID: groupID
            )

            context.insert(event)
            game.events.append(event)
        }

        dismiss()
    }
}
