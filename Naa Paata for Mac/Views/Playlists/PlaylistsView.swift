//
//  PlaylistsView.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/11/26.
//

import SwiftUI
import SwiftData

struct PlaylistsView: View {

    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Playlist.createdAt, order: .reverse)
    private var playlists: [Playlist]

    @State private var viewMode: PlaylistViewMode = .grid
    @State private var isCreating = false

    private let gridColumns = [
        GridItem(
            .adaptive(
                minimum: PlaylistCardView.cardWidth,
                maximum: PlaylistCardView.cardWidth
            ),
            spacing: 22,
            alignment: .top
        )
    ]

    var body: some View {
        Group {
            if playlists.isEmpty {
                EmptyStateView(
                    title: "No Playlists Yet",
                    systemImage: "music.note.list",
                    message: "Create your first playlist to organise your music.",
                    actionTitle: "Create Playlist",
                    action: { isCreating = true }
                )
            } else {
                content
            }
        }
        .navigationTitle("Playlists")
        .toolbar { toolbarContent }
        .sheet(isPresented: $isCreating) {
            CreatePlaylistSheet { name, description, artworkData, songURLs in
                _ = try? PlaylistService(context: modelContext).createPlaylist(
                    name: name,
                    description: description,
                    artworkData: artworkData,
                    songURLs: songURLs
                )
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch viewMode {
        case .grid: gridContent
        case .list: listContent
        }
    }

    private var gridContent: some View {
        ScrollView {
            LazyVGrid(
                columns: gridColumns,
                alignment: .leading,
                spacing: 24
            ) {
                ForEach(playlists) { playlist in
                    NavigationLink(value: playlist) {
                        PlaylistCardView(playlist: playlist)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("Delete", role: .destructive) {
                            try? PlaylistService(context: modelContext).delete(playlist)
                        }
                    }
                }
            }
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var listContent: some View {
        List(playlists) { playlist in
            NavigationLink(value: playlist) {
                PlaylistRowView(playlist: playlist)
            }
            .buttonStyle(.plain)
            .contextMenu {
                Button("Delete", role: .destructive) {
                    try? PlaylistService(context: modelContext).delete(playlist)
                }
            }
        }
        .listStyle(.inset)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {

        ToolbarItem(placement: .primaryAction) {
            Picker("View Mode", selection: $viewMode) {
                ForEach(PlaylistViewMode.allCases, id: \.self) { mode in
                    Image(systemName: mode.systemImage)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .help("Toggle grid/list")
        }

        ToolbarItem(placement: .primaryAction) {
            Button {
                isCreating = true
            } label: {
                Label("New Playlist", systemImage: "plus")
            }
            .help("Create a new playlist")
        }
    }
}
