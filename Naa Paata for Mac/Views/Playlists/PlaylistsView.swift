//
//  PlaylistsView.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/11/26.
//

import SwiftUI

struct PlaylistsView: View {
    var body: some View {
        EmptyStateView(
            title: "Playlists Coming Soon",
            systemImage: "music.note.list",
            message: "Create and manage playlists in a future update."
        )
        .navigationTitle("Playlists")
    }
}
