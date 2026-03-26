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
    @State private var showingShootoutFor = false
    @State private var showingShootoutAgainst = false

    @State private var selectedGoalieID: PersistentIdentifier?
    @State private var shotsAgainstText = ""

    @FocusState private var shotsFieldFocused: Bool

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(game.team?.name ?? "Team")
                        .font(.headline)
                    Text("vs \(game.opponent)")
                        .font(.title3)

                    HStack {
                        Text("Status: \(statusLabel)")
                            .bold()
                        Spacer()
                        if let period = currentPeriodLabel {
                            Text(period)
                        }
                    }

                    HStack {
                        Text("Goals For: \(goalsFor)")
                        Spacer()
                        Text("Goals Against: \(goalsAgainst)")
                    }

                    HStack {
                        Text("Shots: \(shots)")
                        Spacer()
                        Text("Shots Against: \(shotsAgainstTotal)")
                    }

                    HStack {
                        Text("PIM: \(totalPIM)")
                        Spacer()
                        Text("PP Goals: \(powerPlayGoals)")
                    }

                    HStack {
                        Text("SH Goals: \(shortHandedGoals)")
                        Spacer()
                        Text("SH Goals Against: \(shortHandedGoalsAgainst)")
                    }

                    HStack {
                        Text("+: \(plusCount)")
                        Spacer()
                        Text("-: \(minusCount)")
                    }

                    HStack {
                        Text("SO: \(shootoutForGoals)-\(shootoutAgainstGoals)")
                        Spacer()
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Game Control") {
                Button("Start Game") {
                    startGame()
                }
                .disabled(game.isGameStarted && !game.isGameEnded)

                Button("Next Period") {
                    nextPeriod()
                }
                .disabled(!game.isGameStarted || game.isGameEnded || game.isShootout)

                Button("Start Shootout") {
                    startShootout()
                }
                .disabled(!game.isGameStarted || game.isGameEnded || game.isShootout)

                Button("End Game") {
                    endGame()
                }
                .disabled(!game.isGameStarted || game.isGameEnded)
            }

            Section("Quick Actions") {
                Button("Add Goal") {
                    showingGoalFor = true
                }
                .disabled(!canRecordRegularEvents)

                Button("Add Shot") {
                    showingShot = true
                }
                .disabled(!canRecordRegularEvents)

                Button("Add Opponent Shot") {
                    addOpponentShot()
                }
                .disabled(!canRecordRegularEvents)

                Button("Add Penalty") {
                    showingPenalty = true
                }
                .disabled(!canRecordRegularEvents)

                Button("Add Opponent Goal") {
                    showingGoalAgainst = true
                }
                .disabled(!canRecordRegularEvents)

                Button("Add Plus / Minus") {
                    showingPlusMinus = true
                }
                .disabled(!canRecordRegularEvents)

                Button("Add Note") {
                    showingNote = true
                }
                .disabled(!game.isGameStarted || game.isGameEnded)

                Button("Shootout Attempt") {
                    showingShootoutFor = true
                }
                .disabled(!game.isShootout || game.isGameEnded)

                Button("Opponent Shootout Attempt") {
                    showingShootoutAgainst = true
                }
                .disabled(!game.isShootout || game.isGameEnded)

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

            Section("Goalie") {
                if goaliePlayers.isEmpty {
                    Text("No goalies on roster")
                        .foregroundStyle(.secondary)
                } else {
                    Picker("Goalie", selection: $selectedGoalieID) {
                        Text("Select").tag(nil as PersistentIdentifier?)
                        ForEach(goaliePlayers) { player in
                            Text("#\(player.number) \(player.name)")
                                .tag(Optional(player.persistentModelID))
                        }
                    }
                    .onChange(of: selectedGoalieID) { _, newValue in
                        if let newValue {
                            game.goalie = goaliePlayers.first(where: { $0.persistentModelID == newValue })
                        } else {
                            game.goalie = nil
                        }
                    }
                }

                TextField("Official Shots Against (optional)", text: $shotsAgainstText)
                    .keyboardType(.numberPad)
                    .focused($shotsFieldFocused)
                    .onChange(of: shotsAgainstText) { _, newValue in
                        game.shotsAgainst = Int(newValue) ?? 0
                    }
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Done") {
                                shotsFieldFocused = false
                            }
                        }
                    }

                HStack {
                    Text("Tracked Opponent Shots")
                    Spacer()
                    Text("\(trackedOpponentShots)")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Shots Against Used")
                    Spacer()
                    Text("\(shotsAgainstTotal)")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("GA")
                    Spacer()
                    Text("\(goalsAgainst)")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Saves")
                    Spacer()
                    Text("\(saves)")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("SV%")
                    Spacer()
                    Text(savePercentageText)
                        .foregroundStyle(.secondary)
                }
            }
        }
       
        .navigationTitle("Game")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                NavigationLink(destination: GamePeriodBreakdownView(game: game)) {
                    Image(systemName: "chart.xyaxis.line")
                }

                NavigationLink(destination: GameNotesView(game: game)) {
                    Image(systemName: "note.text")
                }

                NavigationLink(destination: GameStatsView(game: game)) {
                    Image(systemName: "chart.bar")
                }
            }
        }
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
        .sheet(isPresented: $showingShootoutFor) {
            AddShootoutEventView(game: game, isForTeam: true)
        }
        .sheet(isPresented: $showingShootoutAgainst) {
            AddShootoutEventView(game: game, isForTeam: false)
        }
        .onAppear {
            selectedGoalieID = game.goalie?.persistentModelID
            shotsAgainstText = game.shotsAgainst == 0 ? "" : "\(game.shotsAgainst)"
        }
    }

    private var goaliePlayers: [Player] {
        (game.team?.players ?? [])
            .filter { $0.position == .goalie }
            .sorted {
                if $0.number == $1.number {
                    return $0.name < $1.name
                }
                return $0.number < $1.number
            }
    }

    private var canRecordRegularEvents: Bool {
        game.isGameStarted && !game.isGameEnded && !game.isShootout
    }

    private var statusLabel: String {
        if game.isGameEnded { return "Final" }
        if game.isShootout { return "Shootout" }
        if game.isGameStarted { return "Live" }
        return "Not Started"
    }

    private var currentPeriodLabel: String? {
        guard game.isGameStarted, let period = game.currentPeriodNumber else { return nil }
        return displayLabel(for: period)
    }

    private func displayLabel(for period: Int) -> String {
        switch period {
        case 1: return "P1"
        case 2: return "P2"
        case 3: return "P3"
        default: return "OT\(period - 3)"
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

    private var trackedOpponentShots: Int {
        game.events.filter { $0.type == .opponentShot }.count
    }

    private var shotsAgainstTotal: Int {
        game.shotsAgainst > 0 ? game.shotsAgainst : trackedOpponentShots
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

    private var shootoutForGoals: Int {
        game.events.filter { $0.type == .shootoutAttemptFor && $0.didScore == true }.count
    }

    private var shootoutAgainstGoals: Int {
        game.events.filter { $0.type == .shootoutAttemptAgainst && $0.didScore == true }.count
    }

    private var saves: Int {
        max(shotsAgainstTotal - goalsAgainst, 0)
    }

    private var savePercentageText: String {
        guard shotsAgainstTotal > 0 else { return ".000" }
        let value = Double(saves) / Double(shotsAgainstTotal)
        return String(format: "%.3f", value)
    }

    private func eventTitle(_ event: GameEvent) -> String {
        switch event.type {
        case .goalFor:
            return "Goal"
        case .shot:
            return "Shot"
        case .opponentShot:
            return "Opponent Shot"
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
        case .gameStart:
            return "Game Start"
        case .gameEnd:
            return "Game End"
        case .shootoutAttemptFor:
            return "Shootout Attempt"
        case .shootoutAttemptAgainst:
            return "Opponent Shootout Attempt"
        }
    }

    private func eventDetail(_ event: GameEvent) -> String? {
        var prefix: String? = nil
        if let period = event.periodNumber {
            prefix = displayLabel(for: period)
        } else if event.type == .shootoutAttemptFor || event.type == .shootoutAttemptAgainst {
            prefix = "SO"
        }

        let mainDetail: String? = {
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

            case .opponentShot:
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

            case .gameStart, .gameEnd:
                return nil

            case .shootoutAttemptFor:
                var parts: [String] = []
                if let player = event.primaryPlayer {
                    parts.append("#\(player.number) \(player.name)")
                }
                parts.append(event.didScore == true ? "Scored" : "Missed")
                return parts.joined(separator: " • ")

            case .shootoutAttemptAgainst:
                return event.didScore == true ? "Scored" : "Missed"
            }
        }()

        if let prefix, let mainDetail, !mainDetail.isEmpty {
            return "\(prefix) • \(mainDetail)"
        } else if let prefix {
            return prefix
        } else {
            return mainDetail
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

        let groupID = newestEvent.groupID
        let relatedEvents = game.events.filter { $0.groupID == groupID }

        for event in relatedEvents {
            context.delete(event)
        }
    }

    private func addOpponentShot() {
        let event = GameEvent(
            type: .opponentShot,
            game: game,
            periodNumber: game.currentPeriodNumber
        )
        context.insert(event)
        game.events.append(event)
    }

    private func startGame() {
        guard !game.isGameStarted || game.isGameEnded else { return }

        game.isGameStarted = true
        game.isGameEnded = false
        game.isShootout = false
        game.currentPeriodNumber = 1

        let event = GameEvent(type: .gameStart, game: game)
        context.insert(event)
        game.events.append(event)
    }

    private func nextPeriod() {
        guard game.isGameStarted, !game.isGameEnded, !game.isShootout else { return }

        if let current = game.currentPeriodNumber {
            game.currentPeriodNumber = current + 1
        } else {
            game.currentPeriodNumber = 1
        }
    }

    private func startShootout() {
        guard game.isGameStarted, !game.isGameEnded else { return }
        game.isShootout = true
    }

    private func endGame() {
        guard game.isGameStarted, !game.isGameEnded else { return }

        // Calculate final score from events
        let teamGoals = game.events.filter { $0.type == .goalFor }.count
        let opponentGoals = game.events.filter { $0.type == .goalAgainst }.count

        // Save final score
        game.teamScore = teamGoals
        game.opponentScore = opponentGoals

        game.isGameEnded = true

        let event = GameEvent(type: .gameEnd, game: game)
        context.insert(event)
        game.events.append(event)
    }
}
