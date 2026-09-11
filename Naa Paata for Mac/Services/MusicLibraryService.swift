//
//  MusicLibraryService.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/11/26.
//

import Foundation
import AVFoundation

protocol MusicLibraryServiceProtocol {
    /// Scans the library folder and returns a sorted list of songs.
    func loadLibrary() async throws -> [Song]
    func delete(_ song: Song) throws
    var libraryFolderURL: URL { get }
}

/// Scans `~/Music/Naa Paata`, reads ID3/metadata, and produces `Song` values.
final class MusicLibraryService: MusicLibraryServiceProtocol {

    private let folderService: MusicFolderService

    /// Extensions we treat as playable audio.
    private static let supportedExtensions: Set<String> = [
        "mp3", "m4a", "aac", "wav", "aif", "aiff", "caf",
        "flac", "alac", "ogg", "oga", "opus"
    ]

    init(folderService: MusicFolderService) {
        self.folderService = folderService
    }

    var libraryFolderURL: URL { folderService.naaPaataFolderURL }

    // MARK: - Public

    func loadLibrary() async throws -> [Song] {
        let folder = try folderService.ensureNaaPaataFolderExists()
        let urls = Self.audioFileURLs(in: folder)

        return await withTaskGroup(of: Song?.self, returning: [Song].self) { group in
            for url in urls {
                group.addTask { await Self.makeSong(from: url) }
            }
            var songs: [Song] = []
            songs.reserveCapacity(urls.count)
            for await song in group {
                if let song { songs.append(song) }
            }
            return songs.sorted {
                $0.title.localizedStandardCompare($1.title) == .orderedAscending
            }
        }
    }
    
    func delete(_ song: Song) throws {
        var resultingURL: NSURL?
        try FileManager.default.trashItem(at: song.url, resultingItemURL: &resultingURL)
    }

    // MARK: - File discovery

    private static func audioFileURLs(in folder: URL) -> [URL] {
        let keys: [URLResourceKey] = [.isRegularFileKey]
        guard let enumerator = FileManager.default.enumerator(
            at: folder,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles, .skipsPackageDescendants],
            errorHandler: { _, _ in true }
        ) else { return [] }

        var urls: [URL] = []
        for case let url as URL in enumerator {
            guard supportedExtensions.contains(url.pathExtension.lowercased()) else { continue }
            urls.append(url)
        }
        return urls
    }

    // MARK: - Metadata

    private static func makeSong(from url: URL) async -> Song? {
        let asset = AVURLAsset(
            url: url,
            options: [AVURLAssetPreferPreciseDurationAndTimingKey: true]
        )

        var title  = url.deletingPathExtension().lastPathComponent
        var artist = "Unknown Artist"
        var album  = "Unknown Album"
        var duration: TimeInterval?
        var artworkData: Data?
        let dateAdded: Date = (try? url.resourceValues(forKeys: [.creationDateKey]).creationDate)
            ?? (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate)
            ?? .distantPast
        
        if let cmDuration = try? await asset.load(.duration),
           cmDuration.isNumeric {
            let seconds = CMTimeGetSeconds(cmDuration)
            if seconds.isFinite, seconds > 0 { duration = seconds }
        }

        if let metadata = try? await asset.load(.commonMetadata) {
            for item in metadata {
                guard let key = item.commonKey else { continue }

                if key == .commonKeyArtwork {
                    if let data = try? await item.load(.dataValue) {
                        artworkData = data
                    }
                    continue
                }

                guard let value = try? await item.load(.stringValue),
                      !value.trimmingCharacters(in: .whitespaces).isEmpty
                else { continue }

                switch key {
                case .commonKeyTitle:     title  = value
                case .commonKeyArtist:    artist = value
                case .commonKeyAlbumName: album  = value
                default: break
                }
            }
        }

        return Song(
            url: url,
            title: title,
            artist: artist,
            album: album,
            duration: duration,
            artworkData: artworkData,
            dateAdded: dateAdded
        )
    }
}
