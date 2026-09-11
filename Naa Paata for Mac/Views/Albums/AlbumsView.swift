//
//  AlbumsView.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/11/26.
//

import SwiftUI

struct AlbumsView: View {

    @ObservedObject var viewModel: MusicLibraryViewModel

    private let columns = [
        GridItem(.adaptive(minimum: 170, maximum: 220), spacing: 22)
    ]

    var body: some View {
        Group {
            if viewModel.albums.isEmpty {
                EmptyStateView(
                    title: "No Albums Yet",
                    systemImage: "square.stack",
                    message: "Albums are created automatically from your songs' album metadata.",
                    actionTitle: "Open Library Folder",
                    action: viewModel.revealLibraryInFinder
                )
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 24) {
                        ForEach(viewModel.albums) { album in
                            NavigationLink(value: album) {
                                AlbumCardView(album: album)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(22)
                }
            }
        }
        .navigationTitle("Albums")
        .navigationDestination(for: Album.self) { album in
            AlbumDetailView(album: album)
        }
    }
}
