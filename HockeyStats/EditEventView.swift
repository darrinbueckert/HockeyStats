import SwiftUI
import SwiftData

private func deleteEventGroup(_ event: GameEvent, in context: ModelContext, from game: Game) {
    let groupedEvents = game.events.filter { $0.groupID == event.groupID }

    if groupedEvents.count > 1 {
        for relatedEvent in groupedEvents {
            context.delete(relatedEvent)
        }
        return
    }

    let sameTimestampEvents = game.events.filter { existing in
        existing.timestamp == event.timestamp
    }

    switch event.type {
    case .goalFor:
        let related = sameTimestampEvents.filter {
            $0.type == .goalFor || $0.type == .shot || $0.type == .plus
        }
        if related.isEmpty {
            context.delete(event)
        } else {
            for relatedEvent in related {
                context.delete(relatedEvent)
            }
        }

    case .goalAgainst:
        let related = sameTimestampEvents.filter {
            $0.type == .goalAgainst || $0.type == .minus
        }
        if related.isEmpty {
            context.delete(event)
        } else {
            for relatedEvent in related {
                context.delete(relatedEvent)
            }
        }

    default:
        context.delete(event)
    }
}

struct EditEventView: View {
    @Environment(\.modelContext) private var context

    let game: Game
    let event: GameEvent

    var body: some View {
        Group {
            switch event.type {
            case .goalFor:
                EditGoalEventView(game: game, event: event)
            case .shot, .opponentShot:
                EditShotEventView(game: game, event: event)
            case .penalty:
                EditPenaltyEventView(game: game, event: event)
            case .plus, .minus:
                EditPlusMinusEventView(game: game, event: event)
            case .goalAgainst:
                EditGoalAgainstEventView(game: game, event: event)
            case .note:
                EditNoteEventView(game: game, event: event)
            case .gameStart, .gameEnd, .shootoutAttemptFor, .shootoutAttemptAgainst, .goalieChange:
                EditSimpleEventView(game: game, event: event)
            }
        }
        .environment(\.modelContext, context)
    }
}

// MARK: - Goal

struct EditGoalEventView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    let game: Game
    let event: GameEvent

    @State private var selectedScorerIndex: Int = -1
    @State private var selectedAssist1Index: Int = -1
    @State private var selectedAssist2Index: Int = -1
    @State private var strength: GoalStrength = .even
    @State private var timestamp: Date = Date()

    init(game: Game, event: GameEvent) {
        self.game = game
        self.event = event

        let players = (game.team?.players ?? []).sorted {
            if $0.number == $1.number { return $0.name < $1.name }
            return $0.number < $1.number
        }

        _selectedScorerIndex = State(initialValue: Self.index(for: event.primaryPlayer, in: players))
        _selectedAssist1Index = State(initialValue: Self.index(for: event.secondaryPlayer, in: players))
        _selectedAssist2Index = State(initialValue: Self.index(for: event.tertiaryPlayer, in: players))
        _strength = State(initialValue: event.strength ?? .even)
        _timestamp = State(initialValue: event.timestamp)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Goal") {
                    Picker("Scorer", selection: $selectedScorerIndex) {
                        Text("Select").tag(-1)
                        ForEach(Array(sortedPlayers.enumerated()), id: \.offset) { index, player in
                            Text("#\(player.number) \(player.name)").tag(index)
                        }
                    }

                    Picker("Assist 1", selection: $selectedAssist1Index) {
                        Text("None").tag(-1)
                        ForEach(Array(sortedPlayers.enumerated()), id: \.offset) { index, player in
                            Text("#\(player.number) \(player.name)").tag(index)
                        }
                    }

                    Picker("Assist 2", selection: $selectedAssist2Index) {
                        Text("None").tag(-1)
                        ForEach(Array(sortedPlayers.enumerated()), id: \.offset) { index, player in
                            Text("#\(player.number) \(player.name)").tag(index)
                        }
                    }

                    Picker("Strength", selection: $strength) {
                        ForEach(GoalStrength.allCases, id: \.self) { value in
                            Text(value.label).tag(value)
                        }
                    }
                }

                Section("Time") {
                    DatePicker("Timestamp", selection: $timestamp)
                }

                Section {
                    Button("Delete Event", role: .destructive) {
                        deleteEventGroup(event, in: context, from: game)
                        dismiss()
                    }
                }
            }
            .navigationTitle("Edit Goal")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let scorer = player(at: selectedScorerIndex) else { return }
                        event.primaryPlayer = scorer
                        event.secondaryPlayer = player(at: selectedAssist1Index)
                        event.tertiaryPlayer = player(at: selectedAssist2Index)
                        event.strength = strength
                        event.timestamp = timestamp
                        dismiss()
                    }
                    .disabled(selectedScorerIndex == -1)
                }
            }
        }
    }

    private var sortedPlayers: [Player] {
        (game.team?.players ?? []).sorted {
            if $0.number == $1.number { return $0.name < $1.name }
            return $0.number < $1.number
        }
    }

    private func player(at index: Int) -> Player? {
        guard index >= 0 && index < sortedPlayers.count else { return nil }
        return sortedPlayers[index]
    }

    private static func index(for player: Player?, in players: [Player]) -> Int {
        guard let player else { return -1 }
        return players.firstIndex { $0.persistentModelID == player.persistentModelID } ?? -1
    }
}

// MARK: - Shot

struct EditShotEventView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    let game: Game
    let event: GameEvent

    @State private var selectedPlayerIndex: Int = -1
    @State private var timestamp: Date = Date()

    init(game: Game, event: GameEvent) {
        self.game = game
        self.event = event

        let players = (game.team?.players ?? []).sorted {
            if $0.number == $1.number { return $0.name < $1.name }
            return $0.number < $1.number
        }

        _selectedPlayerIndex = State(initialValue: Self.index(for: event.primaryPlayer, in: players))
        _timestamp = State(initialValue: event.timestamp)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Shot") {
                    Picker("Player", selection: $selectedPlayerIndex) {
                        Text("Select").tag(-1)
                        ForEach(Array(sortedPlayers.enumerated()), id: \.offset) { index, player in
                            Text("#\(player.number) \(player.name)").tag(index)
                        }
                    }
                }

                Section("Time") {
                    DatePicker("Timestamp", selection: $timestamp)
                }

                Section {
                    Button("Delete Event", role: .destructive) {
                        deleteEventGroup(event, in: context, from: game)
                        dismiss()
                    }
                }
            }
            .navigationTitle("Edit Shot")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let player = player(at: selectedPlayerIndex) else { return }
                        event.primaryPlayer = player
                        event.timestamp = timestamp
                        dismiss()
                    }
                    .disabled(selectedPlayerIndex == -1)
                }
            }
        }
    }

    private var sortedPlayers: [Player] {
        (game.team?.players ?? []).sorted {
            if $0.number == $1.number { return $0.name < $1.name }
            return $0.number < $1.number
        }
    }

    private func player(at index: Int) -> Player? {
        guard index >= 0 && index < sortedPlayers.count else { return nil }
        return sortedPlayers[index]
    }

    private static func index(for player: Player?, in players: [Player]) -> Int {
        guard let player else { return -1 }
        return players.firstIndex { $0.persistentModelID == player.persistentModelID } ?? -1
    }
}

// MARK: - Penalty

struct EditPenaltyEventView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    let game: Game
    let event: GameEvent

    @State private var selectedPlayerIndex: Int = -1
    @State private var minutes: String = ""
    @State private var note: String = ""
    @State private var timestamp: Date = Date()

    init(game: Game, event: GameEvent) {
        self.game = game
        self.event = event

        let players = (game.team?.players ?? []).sorted {
            if $0.number == $1.number { return $0.name < $1.name }
            return $0.number < $1.number
        }

        _selectedPlayerIndex = State(initialValue: Self.index(for: event.primaryPlayer, in: players))
        _minutes = State(initialValue: String(event.pimMinutes ?? 0))
        _note = State(initialValue: event.noteText ?? "")
        _timestamp = State(initialValue: event.timestamp)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Penalty") {
                    Picker("Player", selection: $selectedPlayerIndex) {
                        Text("Select").tag(-1)
                        ForEach(Array(sortedPlayers.enumerated()), id: \.offset) { index, player in
                            Text("#\(player.number) \(player.name)").tag(index)
                        }
                    }

                    TextField("PIM Minutes", text: $minutes)
                    TextField("Note", text: $note)
                }

                Section("Time") {
                    DatePicker("Timestamp", selection: $timestamp)
                }

                Section {
                    Button("Delete Event", role: .destructive) {
                        deleteEventGroup(event, in: context, from: game)
                        dismiss()
                    }
                }
            }
            .navigationTitle("Edit Penalty")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let player = player(at: selectedPlayerIndex) else { return }
                        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
                        event.primaryPlayer = player
                        event.pimMinutes = Int(minutes) ?? 0
                        event.noteText = trimmedNote.isEmpty ? nil : trimmedNote
                        event.timestamp = timestamp
                        dismiss()
                    }
                    .disabled(selectedPlayerIndex == -1)
                }
            }
        }
    }

    private var sortedPlayers: [Player] {
        (game.team?.players ?? []).sorted {
            if $0.number == $1.number { return $0.name < $1.name }
            return $0.number < $1.number
        }
    }

    private func player(at index: Int) -> Player? {
        guard index >= 0 && index < sortedPlayers.count else { return nil }
        return sortedPlayers[index]
    }

    private static func index(for player: Player?, in players: [Player]) -> Int {
        guard let player else { return -1 }
        return players.firstIndex { $0.persistentModelID == player.persistentModelID } ?? -1
    }
}

// MARK: - Plus / Minus

struct EditPlusMinusEventView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    let game: Game
    let event: GameEvent

    @State private var selectedPlayerIndex: Int = -1
    @State private var selectedType: GameEventType = .plus
    @State private var timestamp: Date = Date()

    init(game: Game, event: GameEvent) {
        self.game = game
        self.event = event

        let players = (game.team?.players ?? []).sorted {
            if $0.number == $1.number { return $0.name < $1.name }
            return $0.number < $1.number
        }

        _selectedPlayerIndex = State(initialValue: Self.index(for: event.primaryPlayer, in: players))
        _selectedType = State(initialValue: event.type == .minus ? .minus : .plus)
        _timestamp = State(initialValue: event.timestamp)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Plus / Minus") {
                    Picker("Player", selection: $selectedPlayerIndex) {
                        Text("Select").tag(-1)
                        ForEach(Array(sortedPlayers.enumerated()), id: \.offset) { index, player in
                            Text("#\(player.number) \(player.name)").tag(index)
                        }
                    }

                    Picker("Type", selection: $selectedType) {
                        Text("Plus").tag(GameEventType.plus)
                        Text("Minus").tag(GameEventType.minus)
                    }
                }

                Section("Time") {
                    DatePicker("Timestamp", selection: $timestamp)
                }

                Section {
                    Button("Delete Event", role: .destructive) {
                        deleteEventGroup(event, in: context, from: game)
                        dismiss()
                    }
                }
            }
            .navigationTitle("Edit Plus / Minus")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let player = player(at: selectedPlayerIndex) else { return }
                        event.primaryPlayer = player
                        event.type = selectedType
                        event.timestamp = timestamp
                        dismiss()
                    }
                    .disabled(selectedPlayerIndex == -1)
                }
            }
        }
    }

    private var sortedPlayers: [Player] {
        (game.team?.players ?? []).sorted {
            if $0.number == $1.number { return $0.name < $1.name }
            return $0.number < $1.number
        }
    }

    private func player(at index: Int) -> Player? {
        guard index >= 0 && index < sortedPlayers.count else { return nil }
        return sortedPlayers[index]
    }

    private static func index(for player: Player?, in players: [Player]) -> Int {
        guard let player else { return -1 }
        return players.firstIndex { $0.persistentModelID == player.persistentModelID } ?? -1
    }
}

// MARK: - Goal Against

struct EditGoalAgainstEventView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    let game: Game
    let event: GameEvent

    @State private var strength: GoalStrength = .even
    @State private var note: String = ""
    @State private var timestamp: Date = Date()

    init(game: Game, event: GameEvent) {
        self.game = game
        self.event = event
        _strength = State(initialValue: event.strength ?? .even)
        _note = State(initialValue: event.noteText ?? "")
        _timestamp = State(initialValue: event.timestamp)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Opponent Goal") {
                    Picker("Strength", selection: $strength) {
                        ForEach(GoalStrength.allCases, id: \.self) { value in
                            Text(value.label).tag(value)
                        }
                    }

                    TextField("Note", text: $note)
                }

                Section("Time") {
                    DatePicker("Timestamp", selection: $timestamp)
                }

                Section {
                    Button("Delete Event", role: .destructive) {
                        deleteEventGroup(event, in: context, from: game)
                        dismiss()
                    }
                }
            }
            .navigationTitle("Edit Opponent Goal")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
                        event.strength = strength
                        event.noteText = trimmedNote.isEmpty ? nil : trimmedNote
                        event.timestamp = timestamp
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Note

struct EditNoteEventView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    let game: Game
    let event: GameEvent

    @State private var selectedPlayerIndex: Int = -1
    @State private var note: String = ""
    @State private var timestamp: Date = Date()

    init(game: Game, event: GameEvent) {
        self.game = game
        self.event = event

        let players = (game.team?.players ?? []).sorted {
            if $0.number == $1.number { return $0.name < $1.name }
            return $0.number < $1.number
        }

        _selectedPlayerIndex = State(initialValue: Self.index(for: event.primaryPlayer, in: players))
        _note = State(initialValue: event.noteText ?? "")
        _timestamp = State(initialValue: event.timestamp)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Note") {
                    Picker("Player", selection: $selectedPlayerIndex) {
                        Text("None").tag(-1)
                        ForEach(Array(sortedPlayers.enumerated()), id: \.offset) { index, player in
                            Text("#\(player.number) \(player.name)").tag(index)
                        }
                    }

                    TextField("Note", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Time") {
                    DatePicker("Timestamp", selection: $timestamp)
                }

                Section {
                    Button("Delete Event", role: .destructive) {
                        deleteEventGroup(event, in: context, from: game)
                        dismiss()
                    }
                }
            }
            .navigationTitle("Edit Note")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmedNote.isEmpty else { return }
                        event.primaryPlayer = player(at: selectedPlayerIndex)
                        event.noteText = trimmedNote
                        event.timestamp = timestamp
                        dismiss()
                    }
                    .disabled(note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private var sortedPlayers: [Player] {
        (game.team?.players ?? []).sorted {
            if $0.number == $1.number { return $0.name < $1.name }
            return $0.number < $1.number
        }
    }

    private func player(at index: Int) -> Player? {
        guard index >= 0 && index < sortedPlayers.count else { return nil }
        return sortedPlayers[index]
    }

    private static func index(for player: Player?, in players: [Player]) -> Int {
        guard let player else { return -1 }
        return players.firstIndex { $0.persistentModelID == player.persistentModelID } ?? -1
    }
}

// MARK: - Simple Events

struct EditSimpleEventView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    let game: Game
    let event: GameEvent

    @State private var timestamp: Date = Date()
    @State private var didScore: Bool = false

    init(game: Game, event: GameEvent) {
        self.game = game
        self.event = event
        _timestamp = State(initialValue: event.timestamp)
        _didScore = State(initialValue: event.didScore ?? false)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Time") {
                    DatePicker("Timestamp", selection: $timestamp)
                }

                if needsOutcome {
                    Section("Outcome") {
                        Picker("Result", selection: $didScore) {
                            Text("Scored").tag(true)
                            Text("Missed").tag(false)
                        }
                        .pickerStyle(.segmented)
                    }
                }

                Section {
                    Button("Delete Event", role: .destructive) {
                        deleteEventGroup(event, in: context, from: game)
                        dismiss()
                    }
                }
            }
            .navigationTitle(titleText)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        event.timestamp = timestamp
                        if needsOutcome {
                            event.didScore = didScore
                        }
                        dismiss()
                    }
                }
            }
        }
    }

    private var needsOutcome: Bool {
        event.type == .shootoutAttemptFor || event.type == .shootoutAttemptAgainst
    }

    private var titleText: String {
        switch event.type {
        case .gameStart:
            return "Edit Game Start"
        case .gameEnd:
            return "Edit Game End"
        case .shootoutAttemptFor:
            return "Edit Shootout Attempt"
        case .shootoutAttemptAgainst:
            return "Edit Opponent Shootout"
        default:
            return "Edit Event"
        }
    }
}
