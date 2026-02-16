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
            } header: {
                Text("Packing Options")
            } footer: {
                Text("Add, rename, or remove categories and locations used when adding items to trips. Pack time is always Night before or Morning.")
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
