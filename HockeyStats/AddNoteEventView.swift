import SwiftUI
import SwiftData

struct AddNoteEventView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let game: Game

    @State private var selectedPlayerIndex: Int = -1
    @State private var note = ""

    var body: some View {
        NavigationStack {
            Form {
                Picker("Player", selection: $selectedPlayerIndex) {
                    Text("None").tag(-1)

                    ForEach(Array(sortedPlayers.enumerated()), id: \.offset) { index, player in
                        Text("#\(player.number) \(player.name)")
                            .tag(index)
                    }
                }

                TextField("Note", text: $note, axis: .vertical)
                    .lineLimit(3...6)
            }
            .navigationTitle("Add Note")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmedNote.isEmpty else { return }

                        let selectedPlayer: Player? =
                            selectedPlayerIndex >= 0 && selectedPlayerIndex < sortedPlayers.count
                            ? sortedPlayers[selectedPlayerIndex]
                            : nil

                        let event = GameEvent(
                            type: .note,
                            game: game,
                            primaryPlayer: selectedPlayer,
                            noteText: trimmedNote,
                            periodNumber: game.currentPeriodNumber
                        )

                        context.insert(event)
                        game.events.append(event)
                        dismiss()
                    }
                    .disabled(note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
}
