//
//  SubscriptionSheetPresenter.swift
//  NetNewsWire
//
//  Created by Jeong-Un Kim on 10/29/26.
//  Copyright © 2026 Ranchero Software. All rights reserved.
//

import AppKit

/// Shows the import and export checklist windows as a sheet when the host window is big enough,
/// and as a centered modal window otherwise (the Settings window is too small to hang a 460-point sheet from).
@MainActor final class SubscriptionSheetPresenter {

  private let hostWindow: NSWindow

  init(hostWindow: NSWindow) {
    self.hostWindow = hostWindow
  }

  /// Sheets must fit inside the host: the Settings window is narrower than the main window.
  var preferredWidth: CGFloat {
    min(640, hostWindow.frame.width - 32)
  }

  func present(_ window: NSWindow) {
    if hostWindow.frame.height >= window.frame.height + 80 {
      hostWindow.beginSheet(window)
    } else {
      window.center()
      NSApplication.shared.runModal(for: window)
    }
  }

  func dismiss(_ window: NSWindow, response: NSApplication.ModalResponse) {
    if window.sheetParent != nil {
      hostWindow.endSheet(window, returnCode: response)
    } else {
      NSApplication.shared.stopModal(withCode: response)
      window.orderOut(nil)
    }
  }

  /// Open and save panels still attach to the host window.
  var panelWindow: NSWindow {
    hostWindow
  }
}
