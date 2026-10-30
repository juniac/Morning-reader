//
//  UserKeyboardShortcuts.swift
//  NetNewsWire
//
//  Created by Jeong-Un Kim on 10/29/26.
//  Copyright © 2026 Ranchero Software. All rights reserved.
//

import AppKit
// Name is not Sendable in KeyboardShortcuts 1.17; these constants are only touched on the main thread.
@preconcurrency import KeyboardShortcuts
import RSCore

extension KeyboardShortcuts.Name {
  static let syncAll = Self("syncAll", default: .init(.r))
  static let nextSubscription = Self("nextSubscription", default: .init(.l))
  static let previousSubscription = Self("previousSubscription", default: .init(.h))
  static let previousArticle = Self("previousArticle", default: .init(.k))
  static let nextArticle = Self("nextArticle", default: .init(.j))
  static let toggleRead = Self("toggleRead", default: .init(.m))
  static let toggleStarred = Self("toggleStarred", default: .init(.s))
  static let openInBrowser = Self("openInBrowser", default: .init(.b))
  static let cleanUp = Self("cleanUp", default: .init(.c))
  static let markAllAsRead = Self("markAllAsRead", default: .init(.a))
  static let nextUnread = Self("nextUnread", default: .init(.space))
  static let openInBrowserAndNextArticle = Self("openInBrowserAndNextArticle", default: .init(.n))
}

/// One command the user can rebind in Settings > Shortcuts: the stored shortcut, its label, and the action it sends.
struct UserKeyboardCommand {
  let name: KeyboardShortcuts.Name
  let title: String
  let actionString: String

  @MainActor static let all: [UserKeyboardCommand] = [
    UserKeyboardCommand(name: .syncAll, title: NSLocalizedString("Sync All", comment: "Shortcut"), actionString: "refreshAll:"),
    UserKeyboardCommand(name: .nextSubscription, title: NSLocalizedString("Next Subscription", comment: "Shortcut"), actionString: "goToNextSubscription:"),
    UserKeyboardCommand(name: .previousSubscription, title: NSLocalizedString("Previous Subscription", comment: "Shortcut"), actionString: "goToPreviousSubscription:"),
    UserKeyboardCommand(name: .previousArticle, title: NSLocalizedString("Previous Article", comment: "Shortcut"), actionString: "selectPreviousArticle:"),
    UserKeyboardCommand(name: .nextArticle, title: NSLocalizedString("Next Article", comment: "Shortcut"), actionString: "selectNextArticle:"),
    UserKeyboardCommand(name: .toggleRead, title: NSLocalizedString("Toggle Read", comment: "Shortcut"), actionString: "toggleRead:"),
    UserKeyboardCommand(name: .toggleStarred, title: NSLocalizedString("Toggle Starred", comment: "Shortcut"), actionString: "toggleStarred:"),
    UserKeyboardCommand(name: .openInBrowser, title: NSLocalizedString("Open in Browser", comment: "Shortcut"), actionString: "openInBrowser:"),
    UserKeyboardCommand(name: .openInBrowserAndNextArticle, title: NSLocalizedString("Open in Browser and Next Article", comment: "Shortcut"), actionString: "openInBrowserAndSelectNextArticle:"),
    UserKeyboardCommand(name: .cleanUp, title: NSLocalizedString("Clean Up", comment: "Shortcut"), actionString: "cleanUp:"),
    UserKeyboardCommand(name: .markAllAsRead, title: NSLocalizedString("Mark All as Read", comment: "Shortcut"), actionString: "markAllAsRead:"),
    // Scrolls a long article first, then moves on: the built-in meaning of Space.
    UserKeyboardCommand(name: .nextUnread, title: NSLocalizedString("Next Unread", comment: "Shortcut"), actionString: "scrollOrGoToNextUnread:")
  ]
}

/// Bridges the shortcuts stored by the KeyboardShortcuts package to the app's own in-window key handling.
/// The package's global hot keys are never registered: a bare letter like "j" must only act inside this app,
/// and only when a list or the article view has focus, which is what `MainWindowKeyboardHandler` already guarantees.
@MainActor enum UserKeyboardShortcuts {

  static func keyboardShortcuts() -> Set<KeyboardShortcut> {
    // The package registers a system-wide Carbon hot key for every shortcut it stores, which would eat
    // "j" or "n" in other apps. These keys only act inside the main window, so the hot keys are dropped
    // every time the set is rebuilt: at launch, after recording, and after a reset.
    KeyboardShortcuts.isEnabled = false
    KeyboardShortcuts.disable(UserKeyboardCommand.all.map(\.name))
    return Set(UserKeyboardCommand.all.compactMap { command in
      guard let shortcut = KeyboardShortcuts.getShortcut(for: command.name),
          let dictionary = shortcutDictionary(for: shortcut, actionString: command.actionString) else {
        return nil
      }
      return KeyboardShortcut(dictionary: dictionary)
    })
  }

  static func resetAllToDefaults() {
    KeyboardShortcuts.reset(UserKeyboardCommand.all.map(\.name))
  }

  static func displayString(for name: KeyboardShortcuts.Name) -> String {
    guard let shortcut = KeyboardShortcuts.getShortcut(for: name) else {
      return NSLocalizedString("None", comment: "Shortcut")
    }
    return shortcut.description
  }

  /// The same dictionary shape as GlobalKeyboardShortcuts.plist, so `KeyboardShortcut` can parse it.
  static func shortcutDictionary(for shortcut: KeyboardShortcuts.Shortcut, actionString: String) -> [String: Any]? {
    guard let keyString = keyString(for: shortcut) else {
      return nil
    }
    let modifiers = shortcut.modifiers
    return [
      "key": keyString,
      "action": actionString,
      "shiftModifier": modifiers.contains(.shift),
      "optionModifier": modifiers.contains(.option),
      "commandModifier": modifiers.contains(.command),
      "controlModifier": modifiers.contains(.control)
    ]
  }

  private static func keyString(for shortcut: KeyboardShortcuts.Shortcut) -> String? {
    guard let key = shortcut.key else {
      return nil
    }
    switch key {
    case .space:
      return "[space]"
    case .upArrow:
      return "[uparrow]"
    case .downArrow:
      return "[downarrow]"
    case .leftArrow:
      return "[leftarrow]"
    case .rightArrow:
      return "[rightarrow]"
    case .return:
      return "[return]"
    case .keypadEnter:
      return "[enter]"
    case .delete:
      return "[delete]"
    case .deleteForward:
      return "[deletefunction]"
    case .tab:
      return "[tab]"
    default:
      // The package keeps its key-to-character table private; its description is "⌘⇧R"-style, so take what follows the modifier symbols.
      let character = shortcut.description.drop { "⌃⌥⇧⌘".contains($0) }
      guard character.count == 1 else {
        return nil
      }
      // KeyboardKey matches against charactersIgnoringModifiers, which is uppercase only while Shift is down.
      return shortcut.modifiers.contains(.shift) ? character.uppercased() : character.lowercased()
    }
  }
}
