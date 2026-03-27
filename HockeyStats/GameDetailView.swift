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

    @State private var showingStartGoaliePrompt = false
    @State private var showingChangeGoaliePrompt = false
    @State private var showingEndOfRegulationPrompt = false

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
                    startGamePressed()
                }
                .disabled(game.isGameStarted && !game.isGameEnded)

                Button("Next Period") {
                    nextPeriod()
                }
                .disabled(!game.isGameStarted || game.isGameEnded || game.isShootout)

                Button("End Game") {
                    endGame()
                }
                .disabled(!game.isGameStarted || game.isGameEnded)

                Button("Change Goalie") {
                    showingChangeGoaliePrompt = true
                }
                .disabled(!game.isGameStarted || game.isGameEnded || goaliePlayers.isEmpty)

                Button("Pull Goalie") {
                    pullGoalie()
                }
                .disabled(!game.isGameStarted || game.isGameEnded || game.goalie == nil)
            }

            Section("Quick Actions") {
                Button("Add Goal") {
                    showingGoalFor = true
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canRecordRegularEvents)

                HStack(spacing: 12) {
                    Button {
                        showingShot = true
                    } label: {
                        Text("Detailed Shot")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(!canRecordRegularEvents)

                    Button {
                        addQuickShot()
                    } label: {
                        Text("Quick Shot")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canRecordRegularEvents)
                }

                HStack(spacing: 12) {
                    Button {
                        addOpponentShot()
                    } label: {
                        Text("Opponent Shot")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canRecordRegularEvents)

                    Button {
                        showingGoalAgainst = true
                    } label: {
                        Text("Opponent Goal")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canRecordRegularEvents)
                }

                HStack(spacing: 12) {
                    Button {
                        showingPlusMinus = true
                    } label: {
                        Text("Add Plus / Minus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(!canRecordRegularEvents)

                    Button {
                        showingNote = true
                    } label: {
                        Text("Add Note")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(!canAddNotes)
                }

                Button {
                    showingPenalty = true
                } label: {
                    Text("Add Penalty")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(!canRecordRegularEvents)

                Button(role: .destructive) {
                    undoLastEvent()
                } label: {
                    Text("Undo Last Event")
                }
                .disabled(sortedEvents.isEmpty)
            }

            Section("Shootout") {
                Button("Shootout Attempt") {
                    showingShootoutFor = true
                }
                .disabled(!game.isShootout || game.isGameEnded)

                Button("Opponent Shootout Attempt") {
                    showingShootoutAgainst = true
                }
                .disabled(!game.isShootout || game.isGameEnded)
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
                    HStack {
                        Text("Current Goalie")
                        Spacer()
                        if let goalie = game.goalie {
                            Text("#\(goalie.number) \(goalie.name)")
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Pulled / None")
                                .foregroundStyle(.secondary)
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
        .confirmationDialog(
            "Select Starting Goalie",
            isPresented: $showingStartGoaliePrompt,
            titleVisibility: .visible
        ) {
            ForEach(goaliePlayers) { player in
                Button("#\(player.number) \(player.name)") {
                    applyGoalieChange(to: player.persistentModelID, logEvent: true)
                    startGame()
                }
            }

            Button("Start Without Goalie", role: .destructive) {
                applyGoalieChange(to: nil, logEvent: false)
                startGame()
            }

            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Choose the goalie starting this game.")
        }
        .confirmationDialog(
            "Change Goalie",
            isPresented: $showingChangeGoaliePrompt,
            titleVisibility: .visible
        ) {
            ForEach(goaliePlayers) { player in
                Button("#\(player.number) \(player.name)") {
                    applyGoalieChange(to: player.persistentModelID, logEvent: true)
                }
            }

            Button("No Goalie", role: .destructive) {
                applyGoalieChange(to: nil, logEvent: true)
            }

            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Changing goalies will affect goalie stats for the rest of the game.")
        }
        .confirmationDialog(
            endOfTiedPeriodTitle,
            isPresented: $showingEndOfRegulationPrompt,
            titleVisibility: .visible
        ) {
            Button("Start Overtime") {
                startOvertime()
            }

            Button("Start Shootout") {
                startShootout()
            }

            Button("Cancel", role: .cancel) { }
        } message: {
            Text(endOfTiedPeriodMessage)
        }
        .onAppear {
            shotsAgainstText = game.shotsAgainst == 0 ? "" : "\(game.shotsAgainst)"
        }
    }

    private func applyGoalieChange(to newID: PersistentIdentifier?, logEvent: Bool) {
        let newGoalie = goaliePlayers.first(where: { $0.persistentModelID == newID })
        let oldGoalieID = game.goalie?.persistentModelID

        if oldGoalieID == newID {
            return
        }

        game.goalie = newGoalie

        if logEvent, game.isGameStarted {
            let event = GameEvent(
                type: .goalieChange,
                game: game,
                primaryPlayer: newGoalie,
                noteText: newGoalie == nil ? "Goalie removed" : nil,
                periodNumber: game.currentPeriodNumber
            )
            context.insert(event)
            game.events.append(event)
        }
    }

    private func pullGoalie() {
        applyGoalieChange(to: nil, logEvent: true)
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

    private var canAddNotes: Bool {
        game.isGameStarted
    }

    private var isTied: Bool {
        goalsFor == goalsAgainst
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

    private var endOfTiedPeriodTitle: String {
        let current = game.currentPeriodNumber ?? 3

        switch current {
        case 1, 2, 3:
            return "End of Regulation"
        default:
            return "End of OT\(current - 3)"
        }
    }
    
    private var endOfTiedPeriodMessage: String {
        let current = game.currentPeriodNumber ?? 3

        switch current {
        case 1, 2, 3:
            return "The game is tied after regulation. Choose overtime or shootout."
        default:
            return "The game is still tied after OT\(current - 3). Choose another overtime or shootout."
        }
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
        case .goalieChange:
            if event.primaryPlayer == nil {
                return "Goalie Pulled"
            }

            let hasEarlierGoalieEvent = game.events.contains {
                $0.type == .goalieChange && $0.timestamp < event.timestamp
            }
            return hasEarlierGoalieEvent ? "Goalie Change" : "Starting Goalie"
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
                return "Unassigned"

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

            case .goalieChange:
                if let goalie = event.primaryPlayer {
                    return "#\(goalie.number) \(goalie.name)"
                }
                return nil
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

    private func addQuickShot() {
        let event = GameEvent(
            type: .shot,
            game: game,
            periodNumber: game.currentPeriodNumber
        )
        context.insert(event)
        game.events.append(event)
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

    private func startGamePressed() {
        guard !game.isGameStarted || game.isGameEnded else { return }

        if goaliePlayers.isEmpty || game.goalie != nil {
            startGame()
        } else {
            showingStartGoaliePrompt = true
        }
    }

    private func startGame() {
        guard !game.isGameStarted || game.isGameEnded else { return }

        game.isGameStarted = true
        game.isGameEnded = false
        game.isShootout = false
        game.currentPeriodNumber = 1

        let startEvent = GameEvent(type: .gameStart, game: game)
        context.insert(startEvent)
        game.events.append(startEvent)

        if let goalie = game.goalie {
            let goalieEvent = GameEvent(
                type: .goalieChange,
                game: game,
                primaryPlayer: goalie,
                periodNumber: 1
            )
            context.insert(goalieEvent)
            game.events.append(goalieEvent)
        }
    }

    private func nextPeriod() {
        guard game.isGameStarted, !game.isGameEnded, !game.isShootout else { return }

        let current = game.currentPeriodNumber ?? 1

        if current < 3 {
            game.currentPeriodNumber = current + 1
            return
        }

        if current == 3 {
            if isTied {
                showingEndOfRegulationPrompt = true
            } else {
                endGame()
            }
            return
        }

        // Overtime or later
        if isTied {
            showingEndOfRegulationPrompt = true
        } else {
            endGame()
        }
    }
    private func startOvertime() {
        game.isShootout = false

        let current = game.currentPeriodNumber ?? 3
        if current < 4 {
            game.currentPeriodNumber = 4
        } else {
            game.currentPeriodNumber = current + 1
        }
    }

    private func startShootout() {
        guard game.isGameStarted, !game.isGameEnded else { return }
        game.isShootout = true
    }

    private func endGame() {
        guard game.isGameStarted, !game.isGameEnded else { return }

        let teamGoals = game.events.filter { $0.type == .goalFor }.count
        let opponentGoals = game.events.filter { $0.type == .goalAgainst }.count

        game.teamScore = teamGoals
        game.opponentScore = opponentGoals
        game.isGameEnded = true

        let event = GameEvent(type: .gameEnd, game: game)
        context.insert(event)
        game.events.append(event)
    }
}
