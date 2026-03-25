//
//  AddPenaltyEventView.swift
//  HockeyStats
//
//  Created by DarrinB on 2026-03-24.
//

import SwiftUI
import SwiftData

struct AddPenaltyEventView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let game: Game

    @State private var player: Player?
    @State private var minutes = "2"
    @State private var note = ""

    var body: some View {
        NavigationStack {
            Form {
                Picker("Player", selection: $player) {
                    Text("Select").tag(nil as Player?)
                    ForEach(sortedPlayers) { player in
                        Text("#\(player.number) \(player.name)").tag(Optional(player))
                    }
                }

                TextField("PIM Minutes", text: $minutes)
                TextField("Note", text: $note)
            }
            .navigationTitle("Add Penalty")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let player else { return }

                        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)

                        let event = GameEvent(
                            type: .penalty,
                            game: game,
                            primaryPlayer: player,
                            pimMinutes: Int(minutes) ?? 0,
                            noteText: trimmedNote.isEmpty ? nil : trimmedNote
                        )

                        context.insert(event)
                        game.events.append(event)
                        dismiss()
                    }
                    .disabled(player == nil)
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
