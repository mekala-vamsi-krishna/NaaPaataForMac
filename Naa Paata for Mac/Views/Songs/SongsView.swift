//
//  SongsView.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/11/26.
//

import SwiftUI

struct SongsView: View {

    @ObservedObject var viewModel: MusicLibraryViewModel
    
    @State private var sortOption: SongSortOption = .titleAscending
    @AppStorage("songs.sortOption") private var storedSortRawValue = SongSortOption.titleAscending.rawValue

    private var displayedSongs: [Song] {
        viewModel.songs.sorted(by: sortOption.areInIncreasingOrder)
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.songs.isEmpty {
                ProgressView("Scanning library…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.songs.isEmpty {
                EmptyStateView(
                    title: "No Songs Yet",
                    systemImage: "music.note",
                    message: "Add audio files to ~/Music/Naa Paata to see them here.",
                    actionTitle: "Open Library Folder",
                    action: viewModel.revealLibraryInFinder
                )
            } else {
                songList
            }
        }
        .navigationTitle("Songs")
        .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
        .onAppear {
            sortOption = SongSortOption(rawValue: storedSortRawValue) ?? .titleAscending
        }
        .onChange(of: sortOption) { _, newValue in
            storedSortRawValue = newValue.rawValue
        }
    }

    // MARK: - List

    private var songList: some View {
        List(displayedSongs) { song in
            SongRowView(
                song: song,
                onSelect: { viewModel.play($0, in: displayedSongs) },
                onDelete: viewModel.deleteSong
            )
        }
        .listStyle(.inset)
        .safeAreaInset(edge: .top, spacing: 0) { headerBar }
    }

    // MARK: - Header (Play All / Shuffle All / Sort)

    private var headerBar: some View {
        HStack(spacing: 10) {
            Button {
                // TODO: Playback wiring
            } label: {
                Label("Play All", systemImage: "play.fill")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .help("Play all songs (coming soon)")

            Button {
                // TODO: Playback wiring
            } label: {
                Label("Shuffle All", systemImage: "shuffle")
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .help("Shuffle all songs (coming soon)")

            Spacer()

            sortMenu
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(AppColor.surface)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppColor.separator)
                .frame(height: 1)
        }
    }

    // MARK: - Sort menu

    private var sortMenu: some View {
        Menu {
            Picker("Sort By", selection: $sortOption) {
                ForEach(SongSortOption.allCases) { option in
                    Label(option.title, systemImage: option.systemImage)
                        .tag(option)
                }
            }
            .pickerStyle(.inline)
        } label: {
            Label("Sort", systemImage: "arrow.up.arrow.down")
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .help("Sort songs")
    }
}
