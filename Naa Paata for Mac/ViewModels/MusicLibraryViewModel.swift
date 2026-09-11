//
//  MusicLibraryViewModel.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/11/26.
//

import Foundation
import Combine
import AppKit

@MainActor
final class MusicLibraryViewModel: ObservableObject {

    @Published private(set) var songs: [Song] = []
    @Published private(set) var albums: [Album] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let libraryService: MusicLibraryServiceProtocol

    init(libraryService: MusicLibraryServiceProtocol) {
        self.libraryService = libraryService
    }

    var libraryFolderURL: URL { libraryService.libraryFolderURL }

    // MARK: - Intents

    func loadLibrary() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let songs = try await libraryService.loadLibrary()
            self.songs = songs
            self.albums = Self.groupAlbums(from: songs)
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    func refresh() async {
        await loadLibrary()
    }

    func revealLibraryInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting([libraryService.libraryFolderURL])
    }

    // MARK: - Grouping

    private static func groupAlbums(from songs: [Song]) -> [Album] {
        Dictionary(grouping: songs, by: { $0.album })
            .map { key, value in
                Album(
                    id: key,
                    title: key,
                    artist: value.first?.artist ?? "Unknown Artist",
                    songs: value.sorted {
                        $0.title.localizedStandardCompare($1.title) == .orderedAscending
                    }
                )
            }
            .sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    }
}
