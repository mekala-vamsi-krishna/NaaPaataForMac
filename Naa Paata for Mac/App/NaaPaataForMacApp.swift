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

        _libraryViewModel = StateObject(
            wrappedValue: MusicLibraryViewModel(
                libraryService: libraryService,
                playerService: playerService
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            HomeView(viewModel: libraryViewModel)
                .musicKeyboardShortcuts(for: libraryViewModel)
                .tint(AppColor.primary)
        }
        .modelContainer(for: [Playlist.self, FavouriteSong.self])
        .defaultPosition(.center)
        .windowResizability(.contentSize)
        .windowToolbarStyle(.unified)
    }
}
