//
//  SettingsView.swift
//  packfast
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    var body: some View {
        List {
            Section {
                NavigationLink {
                    ManageOptionsView(optionType: .category)
                } label: {
                    Label("Manage Categories", systemImage: "list.bullet")
                }
                NavigationLink {
                    ManageOptionsView(optionType: .location)
                } label: {
                    Label("Manage Locations", systemImage: "map")
                }
                NavigationLink {
                    ManageOptionsView(optionType: .group)
                } label: {
                    Label("Manage Pack times", systemImage: "clock")
                }
            } header: {
                Text("Packing Options")
            } footer: {
                Text("Add, rename, or remove categories, locations, and pack times used when adding items to trips.")
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .modelContainer(for: [PackingCategory.self, PackingLocation.self, PackingGroup.self], inMemory: true)
    }
}
