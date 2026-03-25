import SwiftUI

struct GameNotesView: View {
    let game: Game

    private var noteEvents: [GameEvent] {
        game.events
            .filter { $0.type == .note }
            .sorted { $0.timestamp > $1.timestamp }
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

            Section("Notes") {
                if noteEvents.isEmpty {
                    Text("No notes for this game")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(noteEvents) { event in
                        VStack(alignment: .leading, spacing: 4) {
                            if let player = event.primaryPlayer {
                                Text("#\(player.number) \(player.name)")
                                    .font(.headline)
                            } else {
                                Text("General Note")
                                    .font(.headline)
                            }

                            Text(event.timestamp.formatted(date: .omitted, time: .standard))
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            if let note = event.noteText, !note.isEmpty {
                                Text(note)
                                    .font(.body)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .navigationTitle("Game Notes")
    }
}
