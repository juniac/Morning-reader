//
//  MainWindowKeyboardHandler.swift
//  NetNewsWire
//
//  Created by Brent Simmons on 12/19/17.
//  Copyright © 2017 Ranchero Software. All rights reserved.
//

import AppKit
import RSCore

@MainActor final class MainWindowKeyboardHandler: KeyboardDelegate {
	static let shared = MainWindowKeyboardHandler()
	let globalShortcuts: Set<KeyboardShortcut>
  /// The shortcuts from Settings > Shortcuts. They take precedence over the built-in ones.
  private var userShortcuts = UserKeyboardShortcuts.keyboardShortcuts()

	init() {
		let f = Bundle.main.path(forResource: "GlobalKeyboardShortcuts", ofType: "plist")!
		let rawShortcuts = NSArray(contentsOfFile: f)! as! [[String: Any]]

		self.globalShortcuts = Set(rawShortcuts.compactMap { KeyboardShortcut(dictionary: $0) })
    NotificationCenter.default.addObserver(self, selector: #selector(userDefaultsDidChange(_:)), name: UserDefaults.didChangeNotification, object: nil)
	}

  @objc private func userDefaultsDidChange(_ note: Notification) {
    Task { @MainActor in
      self.userShortcuts = UserKeyboardShortcuts.keyboardShortcuts()
    }
  }

	func keydown(_ event: NSEvent, in view: NSView) -> Bool {
		let key = KeyboardKey(with: event)
		guard let matchingShortcut = KeyboardShortcut.findMatchingShortcut(in: userShortcuts, key: key) ?? KeyboardShortcut.findMatchingShortcut(in: globalShortcuts, key: key) else {
			return false
		}

		matchingShortcut.perform(with: view)
		return true
	}
}
