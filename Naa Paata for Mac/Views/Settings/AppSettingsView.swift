//
//  AppSettingsView.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/21/26.
//

import SwiftUI

struct AppSettingsView: View {

    @ObservedObject var viewModel: MusicLibraryViewModel

    @EnvironmentObject private var appearanceService: AppearanceService

    var body: some View {
        Form {
            AppearanceSection(service: appearanceService)
            LibrarySection(viewModel: viewModel)
            AboutSection()
        }
        .formStyle(.grouped)
        .frame(width: 520)
        .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Appearance

private struct AppearanceSection: View {

    @ObservedObject var service: AppearanceService

    var body: some View {
        Section {
            HStack(alignment: .top, spacing: 20) {
                ForEach(AppearancePreference.allCases) { preference in
                    AppearanceCard(
                        preference: preference,
                        isSelected: service.preference == preference,
                        onSelect: { service.preference = preference }
                    )
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 6)
        } header: {
            Text("Appearance")
        }
    }
}

// MARK: - Library

private struct LibrarySection: View {

    @ObservedObject var viewModel: MusicLibraryViewModel

    var body: some View {
        Section("Library") {
            LabeledContent("Folder") {
                Text(viewModel.libraryFolderURL.path)
                    .font(.callout.monospaced())
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                    .lineLimit(2)
                    .truncationMode(.middle)
                    .multilineTextAlignment(.trailing)
            }

            HStack(spacing: 10) {
                Button {
                    viewModel.revealLibraryInFinder()
                } label: {
                    Label("Reveal in Finder", systemImage: "finder")
                }

                Button {
                    Task { await viewModel.refresh() }
                } label: {
                    Label("Rescan Library", systemImage: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)

                if viewModel.isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .padding(.leading, 4)
                }

                Spacer(minLength: 0)
            }
            .padding(.top, 2)
        }
    }
}

// MARK: - About

private struct AboutSection: View {

    private var version: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(short) (\(build))"
    }

    var body: some View {
        Section("About") {
            HStack(spacing: 12) {
                if let icon = NSApp.applicationIconImage {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 40, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Naa Paata")
                        .font(.system(size: 13, weight: .semibold))

                    Text("Version \(version)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }
            .padding(.vertical, 4)
        }
    }
}
