//
//  AddTeamView.swift
//  HockeyStats
//
//  Created by DarrinB on 2026-03-24.
//

import SwiftUI
import SwiftData
import PhotosUI
import UIKit

struct AddTeamView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var teamName = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var logoData: Data?

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
            .navigationTitle("Add Team")
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

                        let team = Team(name: trimmedName, logoData: logoData)
                        context.insert(team)
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
