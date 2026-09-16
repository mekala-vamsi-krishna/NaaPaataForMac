//
//  SongRowView.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/11/26.
//

import SwiftUI

struct SongRowView: View {

    let song: Song
    var isCurrentSong: Bool = false
    var isPlaying: Bool = false
    var onSelect: (Song) -> Void = { _ in }
    var onDelete: (Song) -> Void = { _ in }
    var onPlayNext: (Song) -> Void = { _ in }
    var onGoToAlbum: (Song) -> Void = { _ in }

    @State private var isShowingInfo = false
    @State private var isConfirmingDelete = false

    var body: some View {
        HStack(spacing: 12) {
            leadingIndicator

            VStack(alignment: .leading, spacing: 2) {
                Text(song.title)
                    .font(.body)
                    .foregroundStyle(isCurrentSong ? AppColor.primary : AppColor.textPrimary)
                    .lineLimit(1)

                Text(song.artist)
                    .font(.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 16)

            Text(song.album)
                .font(.caption)
                .foregroundStyle(AppColor.textSecondary)
                .lineLimit(1)
                .frame(maxWidth: 220, alignment: .trailing)

            Text(song.formattedDuration)
                .font(.caption.monospacedDigit())
                .foregroundStyle(AppColor.textSecondary)
                .frame(width: 52, alignment: .trailing)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture { onSelect(song) }
        .contextMenu { contextMenu }
        .sheet(isPresented: $isShowingInfo) {
            SongInfoView(song: song)
        }
        .confirmationDialog(
            "Delete “\(song.title)”?",
            isPresented: $isConfirmingDelete,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                withAnimation(.easeInOut(duration: 0.25)) {
                    onDelete(song)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The file will be moved to Trash. You can restore it from Finder.")
        }
    }

    // MARK: - Leading indicator (artwork or equalizer)

    @ViewBuilder
    private var leadingIndicator: some View {
        if isCurrentSong {
            EqualizerBars(
                isPlaying: isPlaying,
                size: 36,
                color: AppColor.primary
            )
            .padding(.horizontal, 6)
        } else {
            ArtworkView(data: song.artworkData, size: 36, cornerRadius: 5)
        }
    }

    // MARK: - Context menu

    @ViewBuilder
    private var contextMenu: some View {
        Button {
            // TODO: Add to playlist wiring
        } label: {
            Label("Add to Playlist", systemImage: "text.badge.plus")
        }

        Divider()

        Button {
            onPlayNext(song)
        } label: {
            Label("Play Next", systemImage: "text.line.first.and.arrowtriangle.forward")
        }

        Divider()

        Button {
            onGoToAlbum(song)
        } label: {
            Label("Go to Album", systemImage: "square.stack")
        }

        Button {
            NSWorkspace.shared.activateFileViewerSelecting([song.url])
        } label: {
            Label("Show in Finder", systemImage: "finder")
        }

        Button {
            isShowingInfo = true
        } label: {
            Label("Song Info", systemImage: "info.circle")
        }

        Divider()

        Button(role: .destructive) {
            isConfirmingDelete = true
        } label: {
            Label("Delete", systemImage: "trash")
                .foregroundStyle(AppColor.danger)
        }
    }
}
