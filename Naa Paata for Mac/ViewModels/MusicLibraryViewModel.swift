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

    // Library
    @Published private(set) var songs: [Song] = []
    @Published private(set) var albums: [Album] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    // Playback
    @Published private(set) var currentSong: Song?
    @Published private(set) var isPlaying = false
    @Published private(set) var progress: Double = 0
    @Published private(set) var elapsed: TimeInterval = 0

    private var queue: [Song] = []
    private var currentIndex: Int?

    private let libraryService: MusicLibraryServiceProtocol
    private let playerService: AudioPlayerServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    var libraryFolderURL: URL { libraryService.libraryFolderURL }

    init(
        libraryService: MusicLibraryServiceProtocol,
        playerService: AudioPlayerServiceProtocol
    ) {
        self.libraryService = libraryService
        self.playerService = playerService
        bindPlayer()
    }

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
    
    func deleteSong(_ song: Song) {
        do {
            try libraryService.delete(song)
            songs.removeAll { $0.id == song.id }
            albums = Self.groupAlbums(from: songs)
        } catch {
            errorMessage = error.localizedDescription
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

    // MARK: - Playback

    /// Plays `song` and sets the full `songs` array as the queue,
    /// so playback continues through the list from that point.
    func play(_ song: Song, in songs: [Song]) {
        guard !songs.isEmpty else { return }
        queue = songs
        currentIndex = songs.firstIndex(where: { $0.id == song.id })
        startPlayback(of: song)
    }

    func togglePlayPause() {
        guard currentSong != nil else { return }
        isPlaying ? playerService.pause() : playerService.play()
    }

    func playNext() {
        guard let currentIndex else { return }
        let nextIndex = currentIndex + 1
        guard nextIndex < queue.count else {
            playerService.pause()
            return
        }
        self.currentIndex = nextIndex
        startPlayback(of: queue[nextIndex])
    }

    func playPrevious() {
        guard let currentIndex else { return }
        let prevIndex = currentIndex - 1
        guard prevIndex >= 0 else { return }
        self.currentIndex = prevIndex
        startPlayback(of: queue[prevIndex])
    }

    func seek(toProgress progress: Double) {
        playerService.seek(toProgress: progress)
    }

    // MARK: - Private

    private func startPlayback(of song: Song) {
        currentSong = song
        do {
            try playerService.load(url: song.url)
            playerService.play()
        } catch {
            errorMessage = "Could not play \"\(song.title)\"."
        }
    }

    private func bindPlayer() {
        playerService.isPlayingPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.isPlaying = $0 }
            .store(in: &cancellables)

        playerService.progressPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.progress = $0 }
            .store(in: &cancellables)

        playerService.elapsedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.elapsed = $0 }
            .store(in: &cancellables)

        playerService.trackDidFinishPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.playNext() }
            .store(in: &cancellables)
    }
}
