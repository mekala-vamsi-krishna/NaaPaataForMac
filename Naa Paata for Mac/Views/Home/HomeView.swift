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
            MusicPlayerView(
                viewModel: viewModel,
                showPlayer: $showPlayer
            )
            .inspectorColumnWidth(min: 320, ideal: 320, max: 320)
        }
        .navigationSplitViewStyle(.balanced)
        .toolbarBackground(.hidden, for: .windowToolbar)

        .onChange(of: selection) { _, _ in
            router.popToRoot()
        }

        .task {
            await viewModel.restoreLastSession()
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
                Label("Reveal Library in Finder", systemImage: "finder")
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
            Group {
                switch selection ?? .songs {
                case .search:
                    SearchView(viewModel: viewModel)

                case .songs:
                    SongsView(viewModel: viewModel)

                case .favourites:
                    FavouritesView(viewModel: viewModel)

                case .albums:
                    AlbumsView(viewModel: viewModel)

                case .playlists:
                    PlaylistsView(viewModel: viewModel)
                }
            }
            .navigationDestination(for: SmartPlaylistRoute.self) { route in
                SmartPlaylistDetailView(
                    kind: route.kind,
                    viewModel: viewModel
                )
            }
        }
        .environmentObject(router)
    }
}
