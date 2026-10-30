//
//  SettingsView.swift
//  NetNewsWire
//
//  Created by Jeong-Un Kim on 10/29/26.
//  Copyright © 2026 Ranchero Software. All rights reserved.
//

import AppKit
@preconcurrency import KeyboardShortcuts
import SwiftUI

/// Re-renders its owner whenever UserDefaults change, so bindings that read AppDefaults directly stay current.
@MainActor final class DefaultsChangeObserver: ObservableObject {
  private var observer: NSObjectProtocol?

  init() {
    observer = NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: .main) { [weak self] _ in
      Task { @MainActor in
        self?.objectWillChange.send()
      }
    }
  }
}

/// A caption under a control, in the Prismy style.
struct SettingsCaption: View {
  let text: LocalizedStringKey

  init(_ text: LocalizedStringKey) {
    self.text = text
  }

  var body: some View {
    Text(text)
      .font(.caption)
      .foregroundStyle(.secondary)
  }
}

// MARK: - Feeds

struct FeedsTab: View {
  @State private var importController: ImportSubscriptionsController?
  @State private var exportController: ExportSubscriptionsController?

  var body: some View {
    Form {
      Section("Data") {
        VStack(alignment: .leading, spacing: 6) {
          Button("Import Subscriptions…") {
            guard let window = NSApp.keyWindow else {
              return
            }
            importController = ImportSubscriptionsController(hostWindow: window, initialContainer: nil)
            importController?.start()
          }
          SettingsCaption("Pick the feeds to add from an OPML file (Feedly, Inoreader, Feedbin, NewsBlur, The Old Reader, and most other readers), a NetNewsWire 3 Subscriptions.plist, a JSON or plain-text list of feed URLs, or an HTML bookmarks file.")
        }
        VStack(alignment: .leading, spacing: 6) {
          Button("Export Subscriptions…") {
            guard let window = NSApp.keyWindow else {
              return
            }
            exportController = ExportSubscriptionsController(hostWindow: window)
            exportController?.start()
          }
          SettingsCaption("Pick the feeds to include in the exported OPML file.")
        }
      }
    }
    .formStyle(.grouped)
  }
}

// MARK: - Shortcuts

struct ShortcutsTab: View {
  @StateObject private var defaults = DefaultsChangeObserver()

  var body: some View {
    Form {
      Section("Shortcuts") {
        ForEach(UserKeyboardCommand.all, id: \.actionString) { command in
          LabeledContent(command.title) {
            ShortcutRecorder(name: command.name)
          }
        }
        SettingsCaption("Click a shortcut, then press the key for it. Press Delete to remove a shortcut, or Esc to keep the current one. These keys work while the sidebar, article list, or article has focus.")
      }
      Section {
        Button("Reset to Defaults") {
          UserKeyboardShortcuts.resetAllToDefaults()
        }
      }
    }
    .formStyle(.grouped)
  }
}

/// The AppKit recorder button; it refreshes on every re-render, which the defaults observer triggers.
private struct ShortcutRecorder: NSViewRepresentable {
  let name: KeyboardShortcuts.Name

  func makeNSView(context: Context) -> ShortcutRecorderButton {
    ShortcutRecorderButton(name: name)
  }

  func updateNSView(_ button: ShortcutRecorderButton, context: Context) {
    button.refresh()
  }
}

// MARK: - Advanced

struct AdvancedTab: View {
  @AppStorage("SendCrashLogsAutomatically") private var sendsCrashLogsAutomatically = true

  var body: some View {
    Form {
      Section("Crash Logs") {
        Toggle("Send automatically", isOn: $sendsCrashLogsAutomatically)
        Button("Privacy Policy") {
          NSApp.sendAction(#selector(AppDelegate.showPrivacyPolicy(_:)), to: nil, from: nil)
        }
      }
    }
    .formStyle(.grouped)
  }
}
