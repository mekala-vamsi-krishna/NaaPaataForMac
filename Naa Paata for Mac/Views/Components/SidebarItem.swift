//
//  SidebarItem.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/11/26.
//

import Foundation

enum SidebarItem: String, CaseIterable, Identifiable {
    case search
    case songs
    case favourites
    case albums
    case playlists

    var id: String { rawValue }

    var title: String {
        switch self {
        case .search:     return "Search"
        case .songs:      return "Songs"
        case .favourites: return "Favourites"
        case .albums:     return "Albums"
        case .playlists:  return "Playlists"
        }
    }

    var systemImage: String {
        switch self {
        case .search:     return "magnifyingglass"
        case .songs:      return "music.note"
        case .albums:     return "square.stack"
        case .playlists:  return "music.note.list"
        case .favourites: return "heart"
        }
    }
}
