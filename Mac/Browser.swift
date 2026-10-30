//
//  Browser.swift
//  Evergren
//
//  Created by Brent Simmons on 2/23/16.
//  Copyright © 2016 Ranchero Software, LLC. All rights reserved.
//

import AppKit
import RSWeb

@MainActor struct Browser {
	/// The user-specified default browser for opening web pages.
	///
	/// The user-assigned default browser, or `nil` if none was assigned
	/// (i.e., the system default should be used).
	static var defaultBrowser: MacWebBrowser? {
		guard let browserID = AppDefaults.defaultBrowserID else {
			return nil
		}
		// Older versions stored a bundle ID rather than a path.
		// Paths always start with "/" and bundle IDs never do.
		if browserID.hasPrefix("/") {
			return MacWebBrowser(path: browserID)
		}
		return MacWebBrowser(bundleIdentifier: browserID)
	}

	/// Opens a URL in the default browser.
	///
	/// - Parameters:
	///   - urlString: The URL to open.
	///   - invert: Whether to invert the "open in background in browser" preference
	static func open(_ urlString: String, invertPreference invert: Bool = false) {
		// Opens according to prefs.
		open(urlString, inBackground: invert ? !AppDefaults.openInBrowserInBackground : AppDefaults.openInBrowserInBackground)
	}

	/// Opens a URL in the default browser.
	///
	/// - Parameters:
	///   - urlString: The URL to open.
	///   - inBackground: Whether to open the URL in the background or not.
	/// - Note: Some browsers (specifically Chromium-derived ones) will ignore the request
	///   to open in the background.
	static func open(_ urlString: String, inBackground: Bool) {
		guard let url = URL(string: urlString), let preparedURL = url.preparedForOpeningInBrowser() else { return }

		// Non-web links (mailto, magnet) go to the system handler, not a browser.
		guard preparedURL.isHTTPOrHTTPSURL() else {
			NSWorkspace.shared.open(preparedURL)
			return
		}

		let configuration = NSWorkspace.OpenConfiguration()
		configuration.requiresUniversalLinks = true
		configuration.promptsUserIfNeeded = false
		if inBackground {
			configuration.activates = false
		}

		if inBackground {
			FocusReclaimer.shared.arm()
		}

		NSWorkspace.shared.open(preparedURL, configuration: configuration) { _, error in
			Task { @MainActor in
				guard error != nil else {
					return
				}
				if let defaultBrowser = defaultBrowser {
					defaultBrowser.openURL(url, inBackground: inBackground)
				} else {
					MacWebBrowser.openURL(url, inBackground: inBackground)
				}
			}
		}
	}
}

/// Chromium browsers come to the front even when asked to open in the background. For a few seconds
/// after such an open, the first activation of another app hands focus straight back to this one.
@MainActor private final class FocusReclaimer {

	static let shared = FocusReclaimer()
	private var observer: NSObjectProtocol?
	private static let windowSeconds: TimeInterval = 4

	func arm() {
		disarm()
		observer = NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main) { [weak self] note in
			let activated = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
			Task { @MainActor in
				guard let self, let activated, activated != .current else {
					return
				}
				self.disarm()
				NSApp.activate(ignoringOtherApps: true)
			}
		}
		DispatchQueue.main.asyncAfter(deadline: .now() + Self.windowSeconds) { [weak self] in
			self?.disarm()
		}
	}

	private func disarm() {
		if let observer {
			NSWorkspace.shared.notificationCenter.removeObserver(observer)
		}
		observer = nil
	}
}

extension Browser {

	static var titleForOpenInBrowserInverted: String {
		let openInBackgroundPref = AppDefaults.openInBrowserInBackground

		return openInBackgroundPref ?
			NSLocalizedString("Open in Browser in Foreground", comment: "Open in Browser in Foreground menu item title") :
			NSLocalizedString("Open in Browser in Background", comment: "Open in Browser in Background menu item title")
	}
}
