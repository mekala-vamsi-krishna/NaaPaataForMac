//
//  EqualizerBars.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/16/26.
//

import SwiftUI

/// Animated equalizer bars used as a "now playing" indicator.
///
/// Bars animate continuously while `isPlaying` is true and freeze in place
/// when it becomes false. The animation is driven by `TimelineView(.animation)`
struct EqualizerBars: View {

    let isPlaying: Bool
    var size: CGFloat = 36
    var barCount: Int = 4
    var color: Color = AppColor.primary

    private let barSpacing: CGFloat = 3
    private let minHeightRatio: CGFloat = 0.15
    private let speed: Double = 5.5

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: !isPlaying)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            HStack(alignment: .center, spacing: barSpacing) {
                ForEach(0..<barCount, id: \.self) { index in
                    Capsule()
                        .fill(color)
                        .frame(
                            width: barWidth,
                            height: barHeight(index: index, time: time)
                        )
                }
            }
            .frame(width: size, height: size)
        }
    }

    // MARK: - Layout helpers

    private var barWidth: CGFloat {
        let totalSpacing = barSpacing * CGFloat(barCount - 1)
        return max((size - totalSpacing) / CGFloat(barCount), 2)
    }

    private func barHeight(index: Int, time: TimeInterval) -> CGFloat {
        // Each bar gets a different phase so they don't move in lockstep.
        let phase = Double(index) * 0.9

        // Two overlapping sine waves give a less mechanical rhythm.
        let wave1 = sin(time * speed + phase)
        let wave2 = sin(time * speed * 0.6 + phase * 1.7)
        let combined = (wave1 + wave2) / 2

        // Map from -1...1 to minHeightRatio...1
        let normalized = (combined + 1) / 2
        let ratio = minHeightRatio + (1 - minHeightRatio) * normalized

        return size * CGFloat(ratio)
    }
}
