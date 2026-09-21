//
//  KeyboardShortcutModifier.swift
//  NaaPaataForMac
//

import SwiftUI
import AppKit

/// - Space => play / pause
/// - ⌘ + ← => previous track
/// - ⌘ + → => next track
///
/// Volume is intentionally left to the system (F10/F11/F12, Touch Bar,
/// Control Center, or the menu-bar slider) so the app doesn't shadow
/// hardware-level controls.
struct KeyboardShortcutModifier: ViewModifier {

    @ObservedObject var viewModel: MusicLibraryViewModel

    @State private var monitor: Any?

    func body(content: Content) -> some View {
        content
            .onAppear { installMonitor() }
            .onDisappear { removeMonitor() }
    }

    // MARK: - Monitor

    private func installMonitor() {
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            handle(event)
        }
    }

    private func removeMonitor() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
    }

    // MARK: - Handling

    /// Returns `nil` to consume the event, or the original event to let
    /// it pass through to the first responder.
    private func handle(_ event: NSEvent) -> NSEvent? {
        guard !isEditingText() else { return event }

        // Arrow keys automatically set `.numericPad` and sometimes `.function`.
        // Intersect with only the modifiers the user consciously pressed.
        let relevantFlags = event.modifierFlags.intersection(
            [.command, .option, .control, .shift]
        )

        switch event.keyCode {
        case 49:                                    // Space
            guard relevantFlags.isEmpty else { return event }
            viewModel.togglePlayPause()
            return nil

        case 123:                                   // ←
            guard relevantFlags == .command else { return event }
            viewModel.playPrevious()
            return nil

        case 124:                                   // →
            guard relevantFlags == .command else { return event }
            viewModel.playNext()
            return nil

        default:
            return event
        }
    }

    private func isEditingText() -> Bool {
        guard let responder = NSApp.keyWindow?.firstResponder else {
            return false
        }
        return responder is NSTextView || responder is NSTextField
    }
}

extension View {
    func musicKeyboardShortcuts(for viewModel: MusicLibraryViewModel) -> some View {
        modifier(KeyboardShortcutModifier(viewModel: viewModel))
    }
}
