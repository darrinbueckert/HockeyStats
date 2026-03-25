import SwiftUI
import SwiftData

struct AddGoalEventView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let game: Game

    @State private var selectedScorerIndex: Int = -1
    @State private var selectedAssist1Index: Int = -1
    @State private var selectedAssist2Index: Int = -1
    @State private var strength: GoalStrength = .even
    @State private var selectedOnIcePlayerIDs: Set<PersistentIdentifier> = []

    var body: some View {
        NavigationStack {
            List {
                Section("Goal") {
                    Picker("Scorer", selection: $selectedScorerIndex) {
                        Text("Select").tag(-1)
                        ForEach(Array(sortedPlayers.enumerated()), id: \.offset) { index, player in
                            Text("#\(player.number) \(player.name)")
                                .tag(index)
                        }
                    }

                    Picker("Assist 1", selection: $selectedAssist1Index) {
                        Text("None").tag(-1)
                        ForEach(Array(sortedPlayers.enumerated()), id: \.offset) { index, player in
                            Text("#\(player.number) \(player.name)")
                                .tag(index)
                        }
                    }

                    Picker("Assist 2", selection: $selectedAssist2Index) {
                        Text("None").tag(-1)
                        ForEach(Array(sortedPlayers.enumerated()), id: \.offset) { index, player in
                            Text("#\(player.number) \(player.name)")
                                .tag(index)
                        }
                    }

                    Picker("Strength", selection: $strength) {
                        ForEach(GoalStrength.allCases, id: \.self) { value in
                            Text(value.label).tag(value)
                        }
                    }
                }

                Section("Players On Ice (+)") {
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
            }
            .navigationTitle("Add Goal")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveGoal()
                    }
                    .disabled(selectedScorerIndex == -1)
                }
            }
        }
    }

    private var sortedPlayers: [Player] {
        (game.team?.players ?? [])
            .filter { $0.position != .goalie }
            .sorted {
                if $0.number == $1.number {
                    return $0.name < $1.name
                }
                return $0.number < $1.number
            }
    }

    private func toggleOnIceSelection(for player: Player) {
        let id = player.persistentModelID
        if selectedOnIcePlayerIDs.contains(id) {
            selectedOnIcePlayerIDs.remove(id)
        } else {
            selectedOnIcePlayerIDs.insert(id)
        }
    }

    private func saveGoal() {
        guard selectedScorerIndex >= 0,
              selectedScorerIndex < sortedPlayers.count else { return }

        let scorer = sortedPlayers[selectedScorerIndex]

        let assist1: Player? =
            selectedAssist1Index >= 0 && selectedAssist1Index < sortedPlayers.count
            ? sortedPlayers[selectedAssist1Index]
            : nil

        let assist2: Player? =
            selectedAssist2Index >= 0 && selectedAssist2Index < sortedPlayers.count
            ? sortedPlayers[selectedAssist2Index]
            : nil

        let eventTime = Date()
        let currentPeriod = game.currentPeriodNumber
        let groupID = UUID().uuidString

        let goalEvent = GameEvent(
            timestamp: eventTime,
            type: .goalFor,
            strength: strength,
            game: game,
            primaryPlayer: scorer,
            secondaryPlayer: assist1,
            tertiaryPlayer: assist2,
            periodNumber: currentPeriod,
            groupID: groupID
        )

        let shotEvent = GameEvent(
            timestamp: eventTime,
            type: .shot,
            game: game,
            primaryPlayer: scorer,
            periodNumber: currentPeriod,
            groupID: groupID
        )

        context.insert(goalEvent)
        context.insert(shotEvent)
        game.events.append(goalEvent)
        game.events.append(shotEvent)

        var selectedOnIcePlayers = sortedPlayers.filter { player in
            selectedOnIcePlayerIDs.contains(player.persistentModelID)
        }

        // Ensure scorer always gets a +
        if !selectedOnIcePlayers.contains(where: { $0.persistentModelID == scorer.persistentModelID }) {
            selectedOnIcePlayers.append(scorer)
        }

        for player in selectedOnIcePlayers {
            let plusEvent = GameEvent(
                timestamp: eventTime,
                type: .plus,
                game: game,
                primaryPlayer: player,
                periodNumber: currentPeriod,
                groupID: groupID
            )
            context.insert(plusEvent)
            game.events.append(plusEvent)
        }

        dismiss()
    }
}
