import SwiftUI
import SwiftData
import UIKit
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Team.name) private var teams: [Team]

    @State private var showingAddTeam = false
    @State private var teamToDelete: Team?
    @State private var showingDeleteTeamAlert = false

    @State private var backupDocument: BackupDocument?
    @State private var showingBackupExporter = false
    @State private var showingBackupImporter = false

    @State private var importMessage = ""
    @State private var showingImportMessage = false

    var body: some View {
        NavigationStack {
            List {
                if teams.isEmpty {
                    ContentUnavailableView(
                        "No Teams Yet",
                        systemImage: "person.3",
                        description: Text("Tap the plus button to add your first team.")
                    )
                } else {
                    ForEach(teams) { team in
                        NavigationLink(destination: TeamRosterView(team: team)) {
                            HStack(spacing: 14) {
                                if let data = team.logoData,
                                   let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 56, height: 56)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                } else {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.15))
                                        .frame(width: 56, height: 56)
                                        .overlay(
                                            Image(systemName: "photo")
                                                .foregroundStyle(.secondary)
                                        )
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(team.name)
                                        .font(.headline)

                                    Text("\(team.players.count) players • \(team.games.count) games")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .onDelete(perform: deleteTeams)
                }
            }
            .navigationTitle("Teams")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Menu {
                        Button("Export Backup") {
                            exportBackup()
                        }

                        Button("Import Backup") {
                            showingBackupImporter = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }

                    Button {
                        showingAddTeam = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTeam) {
                AddTeamView()
            }
            .fileExporter(
                isPresented: $showingBackupExporter,
                document: backupDocument,
                contentType: .json,
                defaultFilename: backupFilename
            ) { result in
                switch result {
                case .success(let url):
                    print("Backup saved to: \(url)")
                case .failure(let error):
                    importMessage = "Backup export failed: \(error.localizedDescription)"
                    showingImportMessage = true
                }
            }
            .fileImporter(
                isPresented: $showingBackupImporter,
                allowedContentTypes: [.json]
            ) { result in
                switch result {
                case .success(let url):
                    let didStartAccessing = url.startAccessingSecurityScopedResource()

                    defer {
                        if didStartAccessing {
                            url.stopAccessingSecurityScopedResource()
                        }
                    }

                    do {
                        let data = try Data(contentsOf: url)
                        try BackupManager.importBackup(from: data, into: context)
                        importMessage = "Backup imported successfully."
                        showingImportMessage = true
                    } catch {
                        importMessage = "Backup import failed: \(error.localizedDescription)"
                        showingImportMessage = true
                    }

                case .failure(let error):
                    importMessage = "Backup import failed: \(error.localizedDescription)"
                    showingImportMessage = true
                }
            }
            .alert(
                teamDeleteTitle,
                isPresented: $showingDeleteTeamAlert
            ) {
                Button("Delete Team", role: .destructive) {
                    if let team = teamToDelete {
                        context.delete(team)
                    }
                    teamToDelete = nil
                }

                Button("Cancel", role: .cancel) {
                    teamToDelete = nil
                }
            } message: {
                Text("This will permanently delete the team, roster, games, and all related stats. This cannot be undone.")
            }
            .alert("Backup", isPresented: $showingImportMessage) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(importMessage)
            }
        }
    }

    private var teamDeleteTitle: String {
        guard let team = teamToDelete else {
            return "Delete Team?"
        }
        return "Delete \(team.name)?"
    }

    private var backupFilename: String {
        let dateText = Date().formatted(.iso8601.year().month().day())
        return "HockeyStatsBackup_\(dateText)"
    }

    private func exportBackup() {
        do {
            let data = try BackupManager.makeBackup(from: teams)
            backupDocument = BackupDocument(data: data)
            showingBackupExporter = true
        } catch {
            importMessage = "Backup export failed: \(error.localizedDescription)"
            showingImportMessage = true
        }
    }

    private func deleteTeams(at offsets: IndexSet) {
        guard let index = offsets.first else { return }
        teamToDelete = teams[index]
        showingDeleteTeamAlert = true
    }
}

#Preview {
    ContentView()
}
