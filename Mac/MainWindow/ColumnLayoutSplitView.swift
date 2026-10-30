//
//  ColumnLayoutSplitView.swift
//  NetNewsWire
//
//  Created by Brent Simmons on 9/19/26.
//  Copyright © 2026 Ranchero Software. All rights reserved.
//

import AppKit

/// A split view whose divider takes the user's border color from Appearance settings.
class BorderedSplitView: NSSplitView {

	override init(frame frameRect: NSRect) {
		super.init(frame: frameRect)
		NotificationCenter.default.addObserver(self, selector: #selector(userDefaultsDidChange(_:)), name: UserDefaults.didChangeNotification, object: nil)
	}

	required init?(coder: NSCoder) {
		super.init(coder: coder)
		NotificationCenter.default.addObserver(self, selector: #selector(userDefaultsDidChange(_:)), name: UserDefaults.didChangeNotification, object: nil)
	}

	override var dividerColor: NSColor {
		AppDefaults.borderColor ?? super.dividerColor
	}

	// macOS 26 does not always draw the thin divider from `dividerColor`, so a custom color is filled directly.
	override func drawDivider(in rect: NSRect) {
		guard let color = AppDefaults.borderColor else {
			super.drawDivider(in: rect)
			return
		}
		color.setFill()
		rect.fill()
	}

	@objc private func userDefaultsDidChange(_ note: Notification) {
		Task { @MainActor in
			self.needsDisplay = true
		}
	}
}

/// The split between the timeline and the article view in column layout.
/// On macOS 26 it extends under the sidebar, so the divider is drawn in the visible part only — otherwise the dimple is off-center.
final class ColumnLayoutSplitView: BorderedSplitView {

	override func drawDivider(in rect: NSRect) {
		super.drawDivider(in: rect.intersection(safeAreaRect))
	}
}
