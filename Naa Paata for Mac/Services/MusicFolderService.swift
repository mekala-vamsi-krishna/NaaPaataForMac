//
//  MusicFolderService.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/11/26.
//
// Services/MusicFolderService.swift

import Foundation

enum MusicFolderError: LocalizedError {
    case creationFailed(URL, Error)

    var errorDescription: String? {
        switch self {
        case .creationFailed(let url, let error):
            return "Failed to create \(url.path): \(error.localizedDescription)"
        }
    }
}

/// Owns everything related to the `~/Music/Naa Paata` folder on disk.
final class MusicFolderService {

    static let folderName = "Naa Paata"

    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    /// `~/Music/Naa Paata`
    var naaPaataFolderURL: URL {
        fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Music", isDirectory: true)
            .appendingPathComponent(Self.folderName, isDirectory: true)
    }

    /// Ensures the folder exists. Creates `~/Music` too if necessary.
    @discardableResult
    func ensureNaaPaataFolderExists() throws -> URL {
        let folder = naaPaataFolderURL
        if fileManager.fileExists(atPath: folder.path) {
            return folder
        }
        do {
            try fileManager.createDirectory(
                at: folder,
                withIntermediateDirectories: true,   // create ~/Music if missing
                attributes: nil
            )
            return folder
        } catch {
            throw MusicFolderError.creationFailed(folder, error)
        }
    }
}
