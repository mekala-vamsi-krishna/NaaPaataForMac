//
//  MusicLibraryViewModel.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/11/26.
//

import Foundation
import Combine
import AppKit
import SwiftData

enum RepeatMode: String, CaseIterable, Codable {
    case off, all, one

    var systemImage: String {
        switch self {
        case .off, .all: return "repeat"
        case .one: return "repeat.1"
        }
    }
}

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
    @Published private(set) var isShuffled = false
    @Published private(set) var repeatMode: RepeatMode = .off

    /// Current playback order. May be shuffled or in source order.
    private var queue: [Song] = []
    /// The unshuffled source list, kept so shuffle can be toggled off.
    private var originalQueue: [Song] = []
    private var currentIndex: Int?

    private let libraryService: MusicLibraryServiceProtocol
    private let playerService: AudioPlayerServiceProtocol
    private let playbackStateService: PlaybackStateServiceProtocol

    private var cancellables = Set<AnyCancellable>()
    
    private var hasRestoredSession = false
    private var lastPersistDate: Date = .distantPast
    private let persistInterval: TimeInterval = 5

    var libraryFolderURL: URL { libraryService.libraryFolderURL }

    init(
        libraryService: MusicLibraryServiceProtocol,
        playerService: AudioPlayerServiceProtocol,
        playbackStateService: PlaybackStateServiceProtocol
    ) {
        self.libraryService = libraryService
        self.playerService = playerService
        self.playbackStateService = playbackStateService
        bindPlayer()
        
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.persistState()
            }
        }
    }
    
    // MARK: - Library

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

    func deleteSong(_ song: Song, in context: ModelContext) {
        do {
            try libraryService.delete(song)
            songs.removeAll { $0.id == song.id }
            albums = Self.groupAlbums(from: songs)
            originalQueue.removeAll { $0.id == song.id }
            queue.removeAll { $0.id == song.id }

            // Remove its favourite record, if any.
            try? FavouritesService(context: context).removeFavourite(song.url)

            if currentSong?.id == song.id {
                playerService.pause()
                currentSong = nil
                queue = []
                originalQueue = []
                currentIndex = nil
            } else if let idx = currentIndex {
                currentIndex = min(idx, max(queue.count - 1, 0))
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func revealLibraryInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting([libraryService.libraryFolderURL])
    }

    func album(for song: Song) -> Album? {
        albums.first { $0.title == song.album }
    }

    // MARK: - Playback entry points

    /// Play the entire list from track 1, linearly. Repeat → `.all`.
    func playAll(_ songs: [Song]) {
        guard let first = songs.first else { return }
        isShuffled = false
        repeatMode = .all
        originalQueue = songs
        queue = songs
        currentIndex = 0
        startPlayback(of: first)
    }

    /// Play the entire list in random order. Shuffle → on, repeat → `.all`.
    func shuffleAll(_ songs: [Song]) {
        guard !songs.isEmpty else { return }
        let shuffled = songs.shuffled()
        isShuffled = true
        repeatMode = .all
        originalQueue = songs
        queue = shuffled
        currentIndex = 0
        startPlayback(of: shuffled[0])
    }

    /// Play `song` from `songs`. Respects the current shuffle state.
    /// Repeat → `.all` so the list keeps going after the last track.
    func play(_ song: Song, in songs: [Song]) {
        guard !songs.isEmpty else { return }
        originalQueue = songs

        if isShuffled {
            let others = songs.filter { $0.id != song.id }.shuffled()
            queue = [song] + others
            currentIndex = 0
        } else {
            queue = songs
            currentIndex = songs.firstIndex(where: { $0.id == song.id }) ?? 0
        }

        repeatMode = .all
        startPlayback(of: song)
    }

    // MARK: - Transport

    func togglePlayPause() {
        guard currentSong != nil else { return }
        isPlaying ? playerService.pause() : playerService.play()
        persistState()
    }

    func playNext() {
        guard currentIndex != nil, !queue.isEmpty else { return }

        // Repeat one — restart current song from the beginning.
        if repeatMode == .one {
            playerService.seek(toProgress: 0)
            return
        }

        advanceToNext()
        persistState()
    }

    func playPrevious() {
        guard currentIndex != nil, !queue.isEmpty else { return }

        // Repeat one — restart current song from the beginning.
        if repeatMode == .one {
            playerService.seek(toProgress: 0)
            return
        }

        goToPrevious()
    }

    func seek(toProgress progress: Double) {
        playerService.seek(toProgress: progress)
        persistState()
    }

    /// Insert `song` immediately after the currently playing track.
    func enqueueNext(_ song: Song) {
        guard let currentIndex else {
            play(song, in: [song])
            return
        }
        guard queue[currentIndex].id != song.id else { return }

        var adjustedIndex = currentIndex
        if let existing = queue.firstIndex(where: { $0.id == song.id }) {
            queue.remove(at: existing)
            if existing < currentIndex { adjustedIndex -= 1 }
        }

        let insertAt = min(adjustedIndex + 1, queue.count)
        queue.insert(song, at: insertAt)
        self.currentIndex = adjustedIndex
    }

    // MARK: - Mode toggles

    func toggleShuffle() {
        isShuffled.toggle()
        guard let current = currentSong, let idx = currentIndex else { return }

        if isShuffled {
            // Keep what's already played, shuffle the rest.
            let played = Array(queue[0...idx])
            let upcoming = idx + 1 < queue.count
                ? Array(queue[(idx + 1)...]).shuffled()
                : []
            queue = played + upcoming
        } else {
            // Restore source order; current song keeps playing.
            queue = originalQueue
            currentIndex = queue.firstIndex(where: { $0.id == current.id })
        }
        persistState()
    }

    func cycleRepeatMode() {
        switch repeatMode {
        case .off: repeatMode = .all
        case .all: repeatMode = .one
        case .one: repeatMode = .off
        }
        applyRepeatMode()
        persistState()
    }

    // MARK: - Private

    private func advanceToNext() {
        guard let idx = currentIndex else { return }
        let nextIdx = idx + 1

        if nextIdx < queue.count {
            currentIndex = nextIdx
            startPlayback(of: queue[nextIdx])
            return
        }

        // End of queue
        guard repeatMode == .all else {
            playerService.pause()
            return
        }

        if isShuffled {
            reshuffleAndRestart()
        } else {
            currentIndex = 0
            startPlayback(of: queue[0])
        }
    }

    private func goToPrevious() {
        guard let idx = currentIndex else { return }
        let prevIdx = idx - 1

        if prevIdx >= 0 {
            currentIndex = prevIdx
            startPlayback(of: queue[prevIdx])
        } else if let current = currentSong {
            // At the top — restart current.
            startPlayback(of: current)
        }
    }

    private func reshuffleAndRestart() {
        var reshuffled = originalQueue.shuffled()

        // Avoid repeating the last song first in the new round.
        if reshuffled.count > 1,
           let last = currentSong,
           reshuffled.first?.id == last.id {
            reshuffled.swapAt(0, 1)
        }

        queue = reshuffled
        currentIndex = 0
        if let first = reshuffled.first {
            startPlayback(of: first)
        }
    }

    private func applyRepeatMode() {
        playerService.setLooping(repeatMode == .one)
    }

    private func startPlayback(of song: Song) {
        currentSong = song
        do {
            try playerService.load(url: song.url)
            applyRepeatMode()
            playerService.play()
        } catch {
            errorMessage = "Could not play \"\(song.title)\"."
        }
        persistState()
    }

    private func bindPlayer() {
        playerService.isPlayingPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.isPlaying = $0 }
            .store(in: &cancellables)

        playerService.progressPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newProgress in
                guard let self else { return }
                
                self.progress = newProgress
                
                let now = Date()
                guard now.timeIntervalSince(self.lastPersistDate) >= self.persistInterval,
                      self.isPlaying
                        else { return }
                
                self.persistState()
            }
            .store(in: &cancellables)

        playerService.elapsedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.elapsed = $0 }
            .store(in: &cancellables)

        playerService.trackDidFinishPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.handleTrackDidFinish() }
            .store(in: &cancellables)
    }

    func restoreLastSession() async {
        guard !hasRestoredSession else { return }
        hasRestoredSession = true

        if songs.isEmpty {
            await loadLibrary()
        }

        guard let state = playbackStateService.load(),
              let currentPath = state.currentSongPath,
              let song = songs.first(where: { $0.url.path == currentPath })
        else {
            return
        }

        let queue = state.queuePaths.compactMap { path in
            songs.first { $0.url.path == path }
        }
        let originalQueue = state.originalQueuePaths.compactMap { path in
            songs.first { $0.url.path == path }
        }

        self.queue = queue.isEmpty ? songs : queue
        self.originalQueue = originalQueue.isEmpty ? self.queue : originalQueue
        self.currentIndex = state.currentIndex
        self.isShuffled = state.isShuffled
        self.repeatMode = RepeatMode(rawValue: state.repeatMode) ?? .off
        self.currentSong = song

        do {
            try playerService.load(url: song.url)
            playerService.setLooping(repeatMode == .one)
            playerService.seek(toTime: state.elapsed)
        } catch {
            errorMessage = "Could not restore last song."
            return
        }

        self.elapsed = state.elapsed
        self.progress = (song.duration ?? 0) > 0
            ? state.elapsed / (song.duration ?? 1)
            : 0
    }
    
    private func persistState() {
        let state = PlaybackState(
            currentSongPath: currentSong?.url.path,
            elapsed: elapsed,
            queuePaths: queue.map(\.url.path),
            originalQueuePaths: originalQueue.map(\.url.path),
            currentIndex: currentIndex,
            isShuffled: isShuffled,
            repeatMode: repeatMode.rawValue,
            savedAt: Date()
        )
        playbackStateService.save(state)
        lastPersistDate = Date()
    }

    private func handleTrackDidFinish() {
        switch repeatMode {
        case .one:
            // Native looping should prevent this — defensive restart.
            if let current = currentSong {
                startPlayback(of: current)
            }
        case .all, .off:
            advanceToNext()
        }
    }

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
