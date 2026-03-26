import SwiftUI
import UniformTypeIdentifiers

struct GameNotesView: View {
    let game: Game

    @State private var htmlDocument: ExportTextDocument?
    @State private var showingHTMLExporter = false

    private var noteEvents: [GameEvent] {
        game.events
            .filter { $0.type == .note }
            .sorted { $0.timestamp > $1.timestamp }
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text(game.team?.name ?? "Team")
                        .font(.headline)
                    Text("vs \(game.opponent)")
                        .font(.title3)
                    Text(game.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Notes") {
                if noteEvents.isEmpty {
                    Text("No notes for this game")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(noteEvents) { event in
                        VStack(alignment: .leading, spacing: 4) {
                            if let player = event.primaryPlayer {
                                Text("#\(player.number) \(player.name)")
                                    .font(.headline)
                            } else {
                                Text("General Note")
                                    .font(.headline)
                            }

                            Text(event.timestamp.formatted(date: .omitted, time: .standard))
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            if let note = event.noteText, !note.isEmpty {
                                Text(note)
                                    .font(.body)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .navigationTitle("Game Notes")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if let url = HTMLExport.makeGameNotesHTML(for: game),
                       let html = try? String(contentsOf: url, encoding: .utf8) {
                        htmlDocument = ExportTextDocument(text: html)
                        showingHTMLExporter = true
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .fileExporter(
            isPresented: $showingHTMLExporter,
            document: htmlDocument,
            contentType: .html,
            defaultFilename: notesReportFilename
        ) { result in
            switch result {
            case .success(let url):
                print("Saved notes HTML to: \(url)")
            case .failure(let error):
                print("Notes HTML export failed: \(error.localizedDescription)")
            }
        }
    }

    private var notesReportFilename: String {
        let teamName = sanitizedFilenamePart(game.team?.name ?? "Team")
        let opponentName = sanitizedFilenamePart(game.opponent)
        let dateText = game.date.formatted(.iso8601.year().month().day())
        return "\(teamName)_vs_\(opponentName)_Notes_\(dateText)"
    }

    private func sanitizedFilenamePart(_ text: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: "\\/:*?\"<>|")
        let cleaned = text.components(separatedBy: invalidCharacters).joined(separator: "")
        return cleaned
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "&", with: "and")
    }
}
