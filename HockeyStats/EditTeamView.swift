import SwiftUI
import PhotosUI
import UIKit

struct EditTeamView: View {
    @Environment(\.dismiss) private var dismiss

    let team: Team

    @State private var teamName: String
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var logoData: Data?

    init(team: Team) {
        self.team = team
        _teamName = State(initialValue: team.name)
        _logoData = State(initialValue: team.logoData)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Team Info") {
                    TextField("Team Name", text: $teamName)
                }

                Section("Team Image") {
                    HStack {
                        Spacer()

                        Group {
                            if let logoData,
                               let uiImage = UIImage(data: logoData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.gray.opacity(0.15))

                                    Image(systemName: "photo")
                                        .font(.system(size: 30))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        Spacer()
                    }
                    .padding(.vertical, 4)

                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label("Choose from Library", systemImage: "photo.on.rectangle")
                    }

                    if logoData != nil {
                        Button(role: .destructive) {
                            logoData = nil
                        } label: {
                            Label("Remove Photo", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle("Edit Team")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmedName = teamName.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmedName.isEmpty else { return }

                        team.name = trimmedName
                        team.logoData = logoData
                        dismiss()
                    }
                    .disabled(teamName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onChange(of: selectedPhoto) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        logoData = data
                    }
                }
            }
        }
    }
}
