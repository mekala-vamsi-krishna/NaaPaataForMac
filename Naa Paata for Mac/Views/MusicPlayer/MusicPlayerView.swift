//
//  MusicPlayerView.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/14/26.
//

import SwiftUI
import AppKit

struct MusicPlayerView: View {

    @ObservedObject var viewModel: MusicLibraryViewModel
    
    @State private var isFavourite = false

    private var song: Song? {
        viewModel.currentSong
    }

    // MARK: - Constants

    private let playerWidth: CGFloat = 320
    private let horizontalPadding: CGFloat = 24
    private let artworkSize: CGFloat = 260
    private let artworkCornerRadius: CGFloat = 16
    private let controlButtonSize: CGFloat = 42
    private let playButtonSize: CGFloat = 54
    private let utilityButtonSize: CGFloat = 42

    // MARK: - Repeat Mode

    private enum RepeatMode {
        case off, all, one

        var systemImage: String {
            switch self {
            case .off, .all: return "repeat"
            case .one:       return "repeat.1"
            }
        }

        var next: RepeatMode {
            switch self {
            case .off: return .all
            case .all: return .one
            case .one: return .off
            }
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            AppColor.surface
                .ignoresSafeArea()

            artworkBackground
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    .black.opacity(0.00),
                    .black.opacity(0.12),
                    .black.opacity(0.42)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)
            .ignoresSafeArea()

            Group {
                if let song {
                    playerContent(song: song)
                } else {
                    emptyState
                }
            }
            .frame(width: playerWidth)
            .frame(maxHeight: .infinity)
        }
    }

    // MARK: - Artwork Background

    private var artworkBackground: some View {
        ZStack {
            if let data = song?.artworkData,
               let image = NSImage(data: data) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .blur(radius: 55)
                    .opacity(0.55)
            } else {
                Color.clear
            }

            Rectangle()
                .fill(.ultraThinMaterial)
        }
        .clipped()
    }

    // MARK: - Player Content

    private func playerContent(song: Song) -> some View {
        VStack(spacing: 0) {
            ArtworkView(
                data: song.artworkData,
                size: artworkSize,
                cornerRadius: artworkCornerRadius
            )
            .frame(width: artworkSize, height: artworkSize)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: artworkCornerRadius,
                    style: .continuous
                )
            )
            .shadow(color: .black.opacity(0.35), radius: 18, y: 10)
            .padding(.bottom, 22)

            trackInfo(song: song)
                .padding(.bottom, 20)

            progressSection(song: song)
                .padding(.bottom, 20)

            backwardForwardPlayControls
                .padding(.bottom, 12)

            utilityControls
        }
        .frame(width: playerWidth)
        .padding(.top, 28)
        .padding(.bottom, 24)
    }

    // MARK: - Track Information

    private func trackInfo(song: Song) -> some View {
        VStack(spacing: 5) {
            MarqueeText(
                text: song.title,
                font: .system(size: 16, weight: .semibold),
                color: .white
            )
            .frame(width: playerWidth - horizontalPadding * 2, height: 22)

            MarqueeText(
                text: song.artist,
                font: .system(size: 13),
                color: .white.opacity(0.75)
            )
            .frame(width: playerWidth - horizontalPadding * 2, height: 18)
        }
    }

    // MARK: - Progress

    private func progressSection(song: Song) -> some View {
        VStack(spacing: 6) {
            ThickSlider(
                value: viewModel.progress,
                trackHeight: 4,
                thumbSize: 12,
                onSeek: { viewModel.seek(toProgress: $0) }
            )
            .frame(
                width: playerWidth - horizontalPadding * 2,
                height: 20
            )

            HStack {
                Text(elapsedString)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.78))

                Spacer()

                Text(song.formattedDuration)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.78))
            }
            .frame(width: playerWidth - horizontalPadding * 2)
        }
    }

    // MARK: - Transport Controls

    private var backwardForwardPlayControls: some View {
        HStack(spacing: 22) {
            NudgeButton(
                systemName: "backward.fill",
                direction: -1,
                size: controlButtonSize,
                action: viewModel.playPrevious
            )

            playPauseButton

            NudgeButton(
                systemName: "forward.fill",
                direction: 1,
                size: controlButtonSize,
                action: viewModel.playNext
            )
        }
        .frame(width: playerWidth)
    }

    // MARK: - Play / Pause

    private var playPauseButton: some View {
        Button {
            viewModel.togglePlayPause()
        } label: {
            Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: 26, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: playButtonSize, height: playButtonSize)
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.plain)
        .animation(
            .spring(response: 0.35, dampingFraction: 0.6),
            value: viewModel.isPlaying
        )
    }

    // MARK: - Utility Controls

    private var utilityControls: some View {
        HStack(spacing: 0) {
            utilityButton(
                systemName: "shuffle",
                isActive: viewModel.isShuffled
            ) {
                viewModel.toggleShuffle()
            }

            utilityButton(
                systemName: viewModel.repeatMode.systemImage,
                isActive: viewModel.repeatMode != .off
            ) {
                viewModel.cycleRepeatMode()
            }

            utilityButton(
                systemName: "list.bullet",
                isActive: false
            ) {

            }

            utilityButton(
                systemName: isFavourite ? "heart.fill" : "heart",
                isActive: isFavourite
            ) {
                isFavourite.toggle()
            }
        }
        .frame(
            width: playerWidth - horizontalPadding * 2,
            height: utilityButtonSize
        )
    }

    private func utilityButton(
        systemName: String,
        isActive: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(isActive ? .white : .white.opacity(0.72))
                .frame(width: utilityButtonSize, height: utilityButtonSize)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "music.note")
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(.white.opacity(0.7))

            Text("Nothing Playing")
                .font(.headline)
                .foregroundStyle(.white)

            Text("Select a song to begin.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(width: playerWidth)
        .frame(maxHeight: .infinity)
    }

    // MARK: - Helpers

    private var elapsedString: String {
        let total = Int(viewModel.elapsed.rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}

// MARK: - Nudge Button

private struct NudgeButton: View {

    let systemName: String
    let direction: CGFloat          // -1 = left, +1 = right
    let size: CGFloat
    let action: () -> Void

    @State private var offsetX: CGFloat = 0

    var body: some View {
        Button {
            action()
            nudge()
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .offset(x: offsetX)
        }
        .buttonStyle(.plain)
    }

    private func nudge() {
        withAnimation(.easeOut(duration: 0.08)) {
            offsetX = direction * 5
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) {
                offsetX = 0
            }
        }
    }
}
