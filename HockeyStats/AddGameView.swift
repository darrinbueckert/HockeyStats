import SwiftUI
import SwiftData

struct AddGameView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let team: Team

    @State private var opponent = ""
    @State private var date = Date()
    @State private var teamScore = ""
    @State private var opponentScore = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Game") {
                    TextField("Opponent", text: $opponent)
                    DatePicker("Date", selection: $date)

                    TextField("Your Score (optional)", text: $teamScore)
                        .keyboardType(.numberPad)

                    TextField("Opponent Score (optional)", text: $opponentScore)
                        .keyboardType(.numberPad)
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

                        let parsedTeamScore = Int(teamScore.trimmingCharacters(in: .whitespacesAndNewlines))
                        let parsedOpponentScore = Int(opponentScore.trimmingCharacters(in: .whitespacesAndNewlines))

                        let finalTeamScore: Int?
                        let finalOpponentScore: Int?

                        if teamScore.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                            opponentScore.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            finalTeamScore = nil
                            finalOpponentScore = nil
                        } else {
                            finalTeamScore = parsedTeamScore ?? 0
                            finalOpponentScore = parsedOpponentScore ?? 0
                        }

                        let game = Game(
                            date: date,
                            opponent: trimmedOpponent,
                            team: team,
                            teamScore: finalTeamScore,
                            opponentScore: finalOpponentScore
                        )

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
