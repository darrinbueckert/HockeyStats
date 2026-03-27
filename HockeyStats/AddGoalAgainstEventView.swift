import SwiftUI
import SwiftData

struct AddGoalAgainstEventView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let game: Game

    @State private var strength: GoalStrength = .even
    @State private var note = ""
    @State private var selectedOnIcePlayerIDs: Set<PersistentIdentifier> = []

    var body: some View {
        NavigationStack {
            List {
                Section("Opponent Goal") {
                    Picker("Strength", selection: $strength) {
                        ForEach(GoalStrength.allCases, id: \.self) { value in
                            Text(value.label).tag(value)
                        }
                    }

                    TextField("Note", text: $note)
                }

                if shouldApplyMinus {
                    Section("Players On Ice (-)") {
                        if sortedPlayers.isEmpty {
                            Text("No players available")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(sortedPlayers) { player in
                                Button {
                                    toggleOnIceSelection(for: player)
                                } label: {
                                    HStack {
                                        Text("#\(player.number)")
                                            .bold()
                                        Text(player.name)
                                        Spacer()
                                        if selectedOnIcePlayerIDs.contains(player.persistentModelID) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(.blue)
                                        }
                                    }
                                }
                                .foregroundStyle(.primary)
                            }
                        }
                    }
                } else {
                    Section {
                        Text("No minus will be applied for a power-play goal against.")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Opponent Goal")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveGoalAgainst()
                    }
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

    private var shouldApplyMinus: Bool {
        strength == .even
    }

    private var isSuddenDeathOvertime: Bool {
        guard let period = game.currentPeriodNumber else { return false }
        return period > 3 && !game.isShootout
    }

    private func toggleOnIceSelection(for player: Player) {
        let id = player.persistentModelID
        if selectedOnIcePlayerIDs.contains(id) {
            selectedOnIcePlayerIDs.remove(id)
        } else {
            selectedOnIcePlayerIDs.insert(id)
        }
    }

    private func saveGoalAgainst() {
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let eventTime = Date()
        let currentPeriod = game.currentPeriodNumber
        let groupID = UUID().uuidString

        let goalAgainstEvent = GameEvent(
            timestamp: eventTime,
            type: .goalAgainst,
            strength: strength,
            game: game,
            noteText: trimmedNote.isEmpty ? nil : trimmedNote,
            periodNumber: currentPeriod,
            groupID: groupID
        )

        context.insert(goalAgainstEvent)
        game.events.append(goalAgainstEvent)

        if shouldApplyMinus {
            let selectedOnIcePlayers = sortedPlayers.filter { player in
                selectedOnIcePlayerIDs.contains(player.persistentModelID)
            }

            for player in selectedOnIcePlayers {
                let minusEvent = GameEvent(
                    timestamp: eventTime,
                    type: .minus,
                    game: game,
                    primaryPlayer: player,
                    periodNumber: currentPeriod,
                    groupID: groupID
                )
                context.insert(minusEvent)
                game.events.append(minusEvent)
            }
        }

        if isSuddenDeathOvertime {
            finishGameImmediately()
        }

        dismiss()
    }

    private func finishGameImmediately() {
        game.teamScore = game.events.filter { $0.type == .goalFor }.count
        game.opponentScore = game.events.filter { $0.type == .goalAgainst }.count
        game.isGameEnded = true

        let endEvent = GameEvent(type: .gameEnd, game: game)
        context.insert(endEvent)
        game.events.append(endEvent)
    }
}
