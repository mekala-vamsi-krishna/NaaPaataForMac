//
//  SettingsView.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/11/26.
//

import SwiftUI

struct SettingsView: View {

    @ObservedObject var viewModel: MusicLibraryViewModel

    var body: some View {
        Form {
            Section("Library") {
                LabeledContent("Folder") {
                    Text(viewModel.libraryFolderURL.path)
                        .font(.callout.monospaced())
                        .foregroundStyle(AppColor.textSecondary)
                        .textSelection(.enabled)
                        .lineLimit(2)
                        .truncationMode(.middle)
                }

                Button {
                    viewModel.revealLibraryInFinder()
                } label: {
                    Label("Reveal in Finder", systemImage: "folder")
                }

                Button {
                    Task { await viewModel.refresh() }
                } label: {
                    Label("Rescan Library", systemImage: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)
            }

            Section("Stats") {
                LabeledContent("Songs", value: "\(viewModel.songs.count)")
                LabeledContent("Albums", value: "\(viewModel.albums.count)")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
        .frame(minWidth: 460, minHeight: 320)
    }
}
