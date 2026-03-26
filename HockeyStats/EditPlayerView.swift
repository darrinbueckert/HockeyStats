import SwiftUI
import SwiftData

struct EditPlayerView: View {
    @Environment(\.dismiss) private var dismiss

    let player: Player

    @State private var name: String
    @State private var number: String
    @State private var position: PlayerPosition

    init(player: Player) {
        self.player = player
        _name = State(initialValue: player.name)
        _number = State(initialValue: String(player.number))
        _position = State(initialValue: player.position)
    }

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
                    Text(player.team?.name ?? "Unknown Team")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Edit Player")
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

                        player.name = trimmedName
                        player.number = Int(number) ?? 0
                        player.position = position

                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
