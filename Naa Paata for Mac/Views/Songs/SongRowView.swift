//
//  SongRowView.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/11/26.
//

import SwiftUI

struct SongRowView: View {
    let song: Song
    var onDelete: (Song) -> Void = { _ in }
    
    @State private var isShowingInfo = false
    @State private var isConfirmingDelete = false

    var body: some View {
        HStack(spacing: 12) {
            ArtworkView(data: song.artworkData, size: 36, cornerRadius: 5)

            VStack(alignment: .leading, spacing: 2) {
                Text(song.title)
                    .font(.body)
                    .foregroundStyle(AppColor.textPrimary)
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

    // MARK: - Context menu

    @ViewBuilder
    private var contextMenu: some View {
        Button {
            // TODO: Play next wiring
        } label: {
            Label("Play Next", systemImage: "text.line.first.and.arrowtriangle.forward")
        }

        Button {
            isShowingInfo = true
        } label: {
            Label("Song Info", systemImage: "info.circle")
        }

        Divider()

        Button {
            // TODO: Go to album wiring
        } label: {
            Label("Go to Album", systemImage: "square.stack")
        }

        Button {
            // TODO: Add to playlist wiring
        } label: {
            Label("Add to Playlist", systemImage: "text.badge.plus")
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
