//
//  FolderSetupView.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/11/26.
//

import SwiftUI

struct HomeView: View {

    @ObservedObject var viewModel: MusicLibraryViewModel

    @StateObject private var router = AppRouter()

    @State private var selection: SidebarItem? = .songs
    @State private var showPlayer = true
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebar
        } detail: {
            content
        }
        .inspector(isPresented: $showPlayer) {
            MusicPlayerView(viewModel: viewModel)
                .inspectorColumnWidth(min: 320, ideal: 320, max: 320)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await viewModel.refresh() }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)
            }

            ToolbarItem(placement: .primaryAction) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showPlayer.toggle()
                    }
                } label: {
                    Label("Toggle Player", systemImage: "sidebar.right")
                }
                .help(showPlayer ? "Hide Player" : "Show Player")
            }
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 1100, minHeight: 650)
        .toolbarBackground(.hidden, for: .windowToolbar)

        .onChange(of: selection) { _, _ in
            router.popToRoot()
        }

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
            .foregroundStyle(AppColor.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Center Content

    @ViewBuilder
    private var content: some View {
        NavigationStack(path: $router.path) {
            switch selection ?? .songs {
            case .search:
                SearchView(viewModel: viewModel)

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
        .environmentObject(router)
        .navigationDestination(for: Album.self) { album in
            AlbumDetailView(album: album, viewModel: viewModel)
        }
    }
}
