//
//  AddGameView.swift
//  HockeyStats
//
//  Created by DarrinB on 2026-03-24.
//

import SwiftUI
import SwiftData

struct AddGameView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let team: Team

    @State private var opponent = ""
    @State private var date = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("Game") {
                    TextField("Opponent", text: $opponent)
                    DatePicker("Date", selection: $date)
                }

                Section("Team") {
                    Text(team.name)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("New Game")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmedOpponent = opponent.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmedOpponent.isEmpty else { return }

                        let game = Game(date: date, opponent: trimmedOpponent, team: team)
                        context.insert(game)
                        team.games.append(game)
                        dismiss()
                    }
                    .disabled(opponent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
