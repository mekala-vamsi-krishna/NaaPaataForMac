//
//  AlbumTrackRowView.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/11/26.
//

import SwiftUI

struct AlbumTrackRowView: View {

    let trackNumber: Int
    let song: Song
    var isCurrentSong: Bool = false
    var isPlaying: Bool = false
    var onSelect: (Song) -> Void = { _ in }
    var onPlayNext: (Song) -> Void = { _ in }

    var body: some View {
        HStack(spacing: 12) {
            if isCurrentSong {
                EqualizerBars(isPlaying: isPlaying, size: 36)
                    .frame(width: 36, alignment: .center)
            } else {
                Text("\(trackNumber)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(AppColor.textSecondary)
                    .frame(width: 36, alignment: .trailing)
            }

            ArtworkView(data: song.artworkData, size: 36, cornerRadius: 5)

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

            Text(song.formattedDuration)
                .font(.caption.monospacedDigit())
                .foregroundStyle(AppColor.textSecondary)
                .frame(width: 52, alignment: .trailing)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture { onSelect(song) }
        .contextMenu {
            Button {
                onPlayNext(song)
            } label: {
                Label("Play Next", systemImage: "text.line.first.and.arrowtriangle.forward")
            }
        }
    }
}
