import SwiftUI

struct EditGameView: View {
    @Environment(\.dismiss) private var dismiss

    let game: Game

    @State private var opponent: String
    @State private var date: Date
    @State private var isHomeGame: Bool
    @State private var teamScore: String
    @State private var opponentScore: String

    init(game: Game) {
        self.game = game
        _opponent = State(initialValue: game.opponent)
        _date = State(initialValue: game.date)
        _isHomeGame = State(initialValue: game.isHomeGame)
        _teamScore = State(initialValue: game.teamScore.map(String.init) ?? "")
        _opponentScore = State(initialValue: game.opponentScore.map(String.init) ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Game") {
                    TextField("Opponent", text: $opponent)
                    DatePicker("Date", selection: $date)

                    Picker("Location", selection: $isHomeGame) {
                        Text("Home").tag(true)
                        Text("Away").tag(false)
                    }
                    .pickerStyle(.segmented)

                    TextField("Your Score (optional)", text: $teamScore)
                        .keyboardType(.numberPad)

                    TextField("Opponent Score (optional)", text: $opponentScore)
                        .keyboardType(.numberPad)
                }

                Section("Preview") {
                    Text(matchupText)
                        .foregroundStyle(.secondary)
                }

                Section("Team") {
                    Text(game.team?.name ?? "Unknown Team")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Edit Game")
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

                        game.opponent = trimmedOpponent
                        game.date = date
                        game.isHomeGame = isHomeGame
                        game.teamScore = finalTeamScore
                        game.opponentScore = finalOpponentScore

                        dismiss()
                    }
                    .disabled(opponent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private var matchupText: String {
        isHomeGame ? "vs \(opponent.isEmpty ? "Opponent" : opponent)" : "@ \(opponent.isEmpty ? "Opponent" : opponent)"
    }
}
