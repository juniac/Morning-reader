//
//  SettingsSideButton.swift
//  NetNewsWire
//
//  Created by Jeong-Un Kim on 10/29/26.
//  Copyright © 2026 Ranchero Software. All rights reserved.
//

import AppKit
import SwiftUI

/// The "Settings" row at the start of the status bar: a gear and label with a material hover background.
struct SettingsSideButton: View {
  @State private var isHovering = false

  var body: some View {
    Button {
      NSApp.sendAction(#selector(AppDelegate.showPreferences(_:)), to: nil, from: nil)
    } label: {
      Label("Settings", systemImage: "gearshape")
        .font(.system(size: 12))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .background {
      if isHovering {
        RoundedRectangle(cornerRadius: 8).fill(.ultraThinMaterial)
      }
    }
    .onHover { isHovering = $0 }
  }
}
