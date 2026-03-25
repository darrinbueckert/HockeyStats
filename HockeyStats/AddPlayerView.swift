import SwiftUI
import SwiftData

struct AddPlayerView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let team: Team

    @State private var name = ""
    @State private var number = ""
    @State private var position: PlayerPosition = .unknown

    var body: some View {
        NavigationStack {
            Form {
                Section("Player") {
                    TextField("Player Name", text: $name)
                    TextField("Number", text: $number)

                    Picker("Position", selection: $position) {
                        ForEach(PlayerPosition.allCases, id: \.self) { value in
                            Text(value.label).tag(value)
                        }
                    }
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
                            team: team,
                            position: position
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
