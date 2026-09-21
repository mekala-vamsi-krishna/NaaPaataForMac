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
                VStack(spacing: 0) {
                    headerBar

                    EmptyStateView(
                        title: "No Playlists Yet",
                        systemImage: "music.note.list",
                        message: "Create your first playlist to organise your music.",
                        actionTitle: "Create Playlist",
                        action: { isCreating = true }
                    )
                }
            } else {
                content
            }
        }
        .navigationTitle("Playlists")
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
        VStack(spacing: 0) {
            headerBar

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
    }

    private var listContent: some View {
        VStack(spacing: 0) {
            headerBar

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
    }

    // MARK: - Header bar

    private var headerBar: some View {
        HStack(spacing: 10) {
            Spacer()

            viewModePicker

            newPlaylistButton
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(AppColor.surface)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppColor.separator)
                .frame(height: 1)
        }
    }

    // MARK: - View mode picker

    private var viewModePicker: some View {
        Picker("View Mode", selection: $viewMode) {
            ForEach(PlaylistViewMode.allCases, id: \.self) { mode in
                Image(systemName: mode.systemImage)
                    .tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .frame(width: 96)
        .help("Toggle grid/list")
    }

    // MARK: - New playlist button

    private var newPlaylistButton: some View {
        Button {
            isCreating = true
        } label: {
            Label("New Playlist", systemImage: "plus")
        }
        .buttonStyle(.bordered)
        .controlSize(.regular)
        .help("Create a new playlist")
    }
}
