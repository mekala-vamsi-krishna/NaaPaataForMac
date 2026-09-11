//
//  FolderSetupView.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/11/26.
//
import SwiftUI

struct HomeView: View {

    @ObservedObject var viewModel: MusicLibraryViewModel
    @State private var selection: SidebarItem? = .songs

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detail
        }
        .frame(minWidth: 940, minHeight: 620)
        .task {
            if viewModel.songs.isEmpty {
                await viewModel.loadLibrary()
            }
        }
        .alert(
            "Something went wrong",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            ),
            actions: { Button("OK", role: .cancel) {} },
            message: { Text(viewModel.errorMessage ?? "") }
        )
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        List(SidebarItem.allCases, selection: $selection) { item in
            Label(item.title, systemImage: item.systemImage)
                .tag(item)
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 180, ideal: 210, max: 260)
        .safeAreaInset(edge: .bottom) {
            sidebarFooter
        }
    }

    private var sidebarFooter: some View {
        VStack(alignment: .leading, spacing: 4) {
            Divider()
            Button {
                viewModel.revealLibraryInFinder()
            } label: {
                Label("Reveal Library in Finder", systemImage: "folder")
                    .font(.caption)
                    .lineLimit(1)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Detail

    @ViewBuilder
    private var detail: some View {
        NavigationStack {
            switch selection ?? .songs {
            case .songs:
                SongsView(viewModel: viewModel)
            case .albums:
                AlbumsView(viewModel: viewModel)
            case .playlists:
                PlaylistsView()
            case .settings:
                SettingsView(viewModel: viewModel)
            }
        }
    }
}
