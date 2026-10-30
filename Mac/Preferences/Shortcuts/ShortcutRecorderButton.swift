//
//  ShortcutRecorderButton.swift
//  NetNewsWire
//
//  Created by Jeong-Un Kim on 10/29/26.
//  Copyright © 2026 Ranchero Software. All rights reserved.
//

import AppKit
@preconcurrency import KeyboardShortcuts

/// Shows a command's shortcut; a click records the next key press into it.
/// The package's own recorder refuses keys without a modifier, and these commands are bare letters, so this one is ours.
@MainActor final class ShortcutRecorderButton: NSButton {

  let name: KeyboardShortcuts.Name
  private var eventMonitor: Any?

  init(name: KeyboardShortcuts.Name) {
    self.name = name
    super.init(frame: .zero)
    bezelStyle = .rounded
    target = self
    action = #selector(beginRecording(_:))
    widthAnchor.constraint(equalToConstant: 160).isActive = true
    refresh()
  }

  required init?(coder: NSCoder) {
    return nil
  }

  func refresh() {
    title = UserKeyboardShortcuts.displayString(for: name)
  }

  @objc private func beginRecording(_ sender: Any?) {
    guard eventMonitor == nil else {
      return
    }
    title = NSLocalizedString("Type a key…", comment: "Shortcut recorder")
    isHighlighted = true

    eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .leftMouseDown, .rightMouseDown]) { [weak self] event in
      guard let self else {
        return event
      }
      // A click anywhere ends recording and is handled normally.
      guard event.type == .keyDown else {
        self.endRecording()
        return event
      }
      self.handle(event)
      return nil
    }
  }

  private func handle(_ event: NSEvent) {
    defer {
      endRecording()
    }
    let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
    if modifiers.isEmpty, event.keyCode == 53 { // Escape: keep the current shortcut.
      return
    }
    if modifiers.isEmpty, event.keyCode == 51 || event.keyCode == 117 { // Delete, forward delete: remove the shortcut.
      KeyboardShortcuts.setShortcut(nil, for: name)
      return
    }
    guard let shortcut = KeyboardShortcuts.Shortcut(event: event) else {
      NSSound.beep()
      return
    }
    KeyboardShortcuts.setShortcut(shortcut, for: name)
  }

  private func endRecording() {
    if let eventMonitor {
      NSEvent.removeMonitor(eventMonitor)
      self.eventMonitor = nil
    }
    isHighlighted = false
    refresh()
  }
}
