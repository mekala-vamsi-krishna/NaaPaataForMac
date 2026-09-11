//
//  Naa_Paata_for_MacApp.swift
//  Naa Paata for Mac
//
//  Created by Mekala Vamsi Krishna on 9/11/26.
//
// App/NaaPaataForMacApp.swift
import SwiftUI

@main
struct NaaPaataForMacApp: App {

    @StateObject private var libraryViewModel: MusicLibraryViewModel

    init() {
        let folderService = MusicFolderService()
        let libraryService = MusicLibraryService(folderService: folderService)
        _libraryViewModel = StateObject(
            wrappedValue: MusicLibraryViewModel(libraryService: libraryService)
        )
    }

    var body: some Scene {
        WindowGroup {
            HomeView(viewModel: libraryViewModel)
        }
        .defaultSize(width: 1100, height: 720)
        .windowToolbarStyle(.unified)
    }
}
