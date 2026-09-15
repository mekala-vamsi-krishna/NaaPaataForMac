//
//  ThickSlider.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/15/26.
//

import SwiftUI

struct ThickSlider: View {

    let value: Double
    var trackHeight: CGFloat = 4
    var thumbSize: CGFloat = 12
    var onSeek: (Double) -> Void

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let inset = thumbSize / 2
            let trackWidth = max(width - thumbSize, 1)
            let clamped = min(max(value, 0), 1)
            let fillWidth = trackWidth * clamped
            let thumbCenter = inset + fillWidth

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.white.opacity(0.28))
                    .frame(width: trackWidth, height: trackHeight)
                    .offset(x: inset)

                Capsule()
                    .fill(.white)
                    .frame(width: max(fillWidth, trackHeight), height: trackHeight)
                    .offset(x: inset)

                Circle()
                    .fill(.white)
                    .frame(width: thumbSize, height: thumbSize)
                    .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
                    .offset(x: thumbCenter - thumbSize / 2)
            }
            .frame(width: width, height: max(trackHeight, thumbSize))
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let x = gesture.location.x - inset
                        let ratio = x / trackWidth
                        onSeek(min(1, max(0, ratio)))
                    }
            )
        }
        .frame(height: max(trackHeight, thumbSize))
    }
}
