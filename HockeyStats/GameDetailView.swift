import SwiftUI
import SwiftData

struct GameDetailView: View {
    @Environment(\.modelContext) private var context

    let game: Game

    @State private var showingGoalFor = false
    @State private var showingShot = false
    @State private var showingPenalty = false
    @State private var showingGoalAgainst = false
    @State private var showingPlusMinus = false
    @State private var showingNote = false

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(game.team?.name ?? "Team")
                        .font(.headline)
                    Text("vs \(game.opponent)")
                        .font(.title3)

                    HStack {
                        Text("Goals For: \(goalsFor)")
                        Spacer()
                        Text("Goals Against: \(goalsAgainst)")
                    }

                    HStack {
                        Text("Shots: \(shots)")
                        Spacer()
                        Text("PIM: \(totalPIM)")
                    }

                    HStack {
                        Text("PP Goals: \(powerPlayGoals)")
                        Spacer()
                        Text("SH Goals: \(shortHandedGoals)")
                    }

                    HStack {
                        Text("+: \(plusCount)")
                        Spacer()
                        Text("-: \(minusCount)")
                    }

                    HStack {
                        Text("SH Goals Against: \(shortHandedGoalsAgainst)")
                        Spacer()
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Quick Actions") {
                Button("Add Goal") {
                    showingGoalFor = true
                }

                Button("Add Shot") {
                    showingShot = true
                }

                Button("Add Penalty") {
                    showingPenalty = true
                }

                Button("Add Opponent Goal") {
                    showingGoalAgainst = true
                }

                Button("Add Plus / Minus") {
                    showingPlusMinus = true
                }

                Button("Add Note") {
                    showingNote = true
                }

                Button(role: .destructive) {
                    undoLastEvent()
                } label: {
                    Text("Undo Last Event")
                }
                .disabled(sortedEvents.isEmpty)
            }

            Section("Event Log") {
                if sortedEvents.isEmpty {
                    Text("No events yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sortedEvents) { event in
                        NavigationLink(destination: EditEventView(game: game, event: event)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(eventTitle(event))
                                    .font(.headline)

                                Text(event.timestamp.formatted(date: .omitted, time: .standard))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                if let detail = eventDetail(event), !detail.isEmpty {
                                    Text(detail)
                                        .font(.subheadline)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .onDelete(perform: deleteEvents)
                }
            }
        }
        .navigationTitle("Game")
        .sheet(isPresented: $showingGoalFor) {
            AddGoalEventView(game: game)
        }
        .sheet(isPresented: $showingShot) {
            AddShotEventView(game: game)
        }
        .sheet(isPresented: $showingPenalty) {
            AddPenaltyEventView(game: game)
        }
        .sheet(isPresented: $showingGoalAgainst) {
            AddGoalAgainstEventView(game: game)
        }
        .sheet(isPresented: $showingPlusMinus) {
            AddPlusMinusEventView(game: game)
        }
        .sheet(isPresented: $showingNote) {
            AddNoteEventView(game: game)
        }
    }

    private var sortedEvents: [GameEvent] {
        game.events.sorted { $0.timestamp > $1.timestamp }
    }

    private var goalsFor: Int {
        game.events.filter { $0.type == .goalFor }.count
    }

    private var goalsAgainst: Int {
        game.events.filter { $0.type == .goalAgainst }.count
    }

    private var shots: Int {
        game.events.filter { $0.type == .shot }.count
    }

    private var totalPIM: Int {
        game.events
            .filter { $0.type == .penalty }
            .compactMap { $0.pimMinutes }
            .reduce(0, +)
    }

    private var powerPlayGoals: Int {
        game.events.filter { $0.type == .goalFor && $0.strength == .powerPlay }.count
    }

    private var shortHandedGoals: Int {
        game.events.filter { $0.type == .goalFor && $0.strength == .shortHanded }.count
    }

    private var shortHandedGoalsAgainst: Int {
        game.events.filter { $0.type == .goalAgainst && $0.strength == .shortHanded }.count
    }

    private var plusCount: Int {
        game.events.filter { $0.type == .plus }.count
    }

    private var minusCount: Int {
        game.events.filter { $0.type == .minus }.count
    }

    private func eventTitle(_ event: GameEvent) -> String {
        switch event.type {
        case .goalFor:
            return "Goal"
        case .shot:
            return "Shot"
        case .penalty:
            return "Penalty"
        case .plus:
            return "Plus"
        case .minus:
            return "Minus"
        case .goalAgainst:
            return "Opponent Goal"
        case .note:
            return "Note"
        }
    }

    private func eventDetail(_ event: GameEvent) -> String? {
        switch event.type {
        case .goalFor:
            var parts: [String] = []
            if let scorer = event.primaryPlayer {
                parts.append("Scorer: #\(scorer.number) \(scorer.name)")
            }
            if let assist1 = event.secondaryPlayer {
                parts.append("A1: #\(assist1.number) \(assist1.name)")
            }
            if let assist2 = event.tertiaryPlayer {
                parts.append("A2: #\(assist2.number) \(assist2.name)")
            }
            if let strength = event.strength {
                parts.append("Strength: \(strength.label)")
            }
            return parts.joined(separator: " • ")

        case .shot:
            if let player = event.primaryPlayer {
                return "#\(player.number) \(player.name)"
            }
            return nil

        case .penalty:
            var parts: [String] = []
            if let player = event.primaryPlayer {
                parts.append("#\(player.number) \(player.name)")
            }
            if let mins = event.pimMinutes {
                parts.append("\(mins) min")
            }
            if let note = event.noteText, !note.isEmpty {
                parts.append(note)
            }
            return parts.joined(separator: " • ")

        case .plus, .minus:
            if let player = event.primaryPlayer {
                return "#\(player.number) \(player.name)"
            }
            return nil

        case .goalAgainst:
            var parts: [String] = []
            if let strength = event.strength {
                parts.append("Strength: \(strength.label)")
            }
            if let note = event.noteText, !note.isEmpty {
                parts.append(note)
            }
            return parts.joined(separator: " • ")

        case .note:
            var parts: [String] = []
            if let player = event.primaryPlayer {
                parts.append("#\(player.number) \(player.name)")
            }
            if let note = event.noteText, !note.isEmpty {
                parts.append(note)
            }
            return parts.joined(separator: " • ")
        }
    }

    private func deleteEvents(at offsets: IndexSet) {
        for index in offsets {
            let event = sortedEvents[index]
            context.delete(event)
        }
    }

    private func undoLastEvent() {
        guard let newestEvent = sortedEvents.first else { return }
        context.delete(newestEvent)
    }
}
