//
//  AddPlayerView.swift
//  HockeyStats
//
//  Created by DarrinB on 2026-03-24.
//

import SwiftUI
import SwiftData

struct AddPlayerView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let team: Team

    @State private var name = ""
    @State private var number = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Player") {
                    TextField("Player Name", text: $name)
                    TextField("Number", text: $number)
                }

                Section("Team") {
                    Text(team.name)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Add Player")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmedName.isEmpty else { return }

                        let player = Player(
                            name: trimmedName,
                            number: Int(number) ?? 0,
                            team: team
                        )

                        context.insert(player)
                        team.players.append(player)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
