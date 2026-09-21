//
//  Naa_Paata_for_MacApp.swift
//  Naa Paata for Mac
//
//  Created by Mekala Vamsi Krishna on 9/11/26.
//

import SwiftUI
import SwiftData

@main
struct NaaPaataForMacApp: App {

    @StateObject private var libraryViewModel: MusicLibraryViewModel

    init() {
        let folderService = MusicFolderService()
        let libraryService = MusicLibraryService(folderService: folderService)
        let playerService = AudioPlayerService()
        let playbackStateService = PlaybackStateService()

        _libraryViewModel = StateObject(
            wrappedValue: MusicLibraryViewModel(
                libraryService: libraryService,
                playerService: playerService,
                playbackStateService: playbackStateService
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            HomeView(viewModel: libraryViewModel)
                .musicKeyboardShortcuts(for: libraryViewModel)
                .tint(AppColor.primary)
                .background(WindowConfigurator())
        }
        .modelContainer(for: [Playlist.self, FavouriteSong.self])
        .windowResizability(.contentSize)
        .windowToolbarStyle(.unified)

        Window("Mini Player", id: WindowID.miniPlayer) {
            MiniPlayerView(viewModel: libraryViewModel)
        }
        .modelContainer(for: [Playlist.self, FavouriteSong.self])
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 380, height: 380)
        .defaultPosition(.topTrailing)
    }
}
