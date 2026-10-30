//
//  MarkAllAsReadConfirmation.swift
//  NetNewsWire
//
//  Created by Jeong-Un Kim on 10/29/26.
//  Copyright © 2026 Ranchero Software. All rights reserved.
//

import AppKit

/// Gates every "mark all as read" command behind the General preference "Ask before marking all as read".
@MainActor enum MarkAllAsReadConfirmation {

  /// Runs `markAsRead` at once, or after the user confirms when the preference asks for it.
  static func run(on window: NSWindow?, articleCount: Int, _ markAsRead: @escaping @MainActor () -> Void) {
    guard AppDefaults.confirmMarkAllAsRead, articleCount > 0 else {
      markAsRead()
      return
    }

    let alert = NSAlert()
    alert.alertStyle = .warning
    alert.messageText = NSLocalizedString("Mark All as Read?", comment: "Mark all as read confirmation")
    let formatString = NSLocalizedString("%d articles will be marked as read. You can undo this.", comment: "Mark all as read confirmation")
    alert.informativeText = String(format: formatString, articleCount)
    alert.addButton(withTitle: NSLocalizedString("Mark All as Read", comment: "Mark all as read confirmation"))
    alert.addButton(withTitle: NSLocalizedString("Cancel", comment: "Mark all as read confirmation"))

    guard let window else {
      if alert.runModal() == .alertFirstButtonReturn {
        markAsRead()
      }
      return
    }
    alert.beginSheetModal(for: window) { response in
      if response == .alertFirstButtonReturn {
        markAsRead()
      }
    }
  }
}
