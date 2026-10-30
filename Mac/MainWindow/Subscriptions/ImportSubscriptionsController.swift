//
//  ImportSubscriptionsController.swift
//  NetNewsWire
//
//  Created by Jeong-Un Kim on 10/29/26.
//  Copyright © 2026 Ranchero Software. All rights reserved.
//

import AppKit
import Account
import RSCore
import RSTree
import UniformTypeIdentifiers

/// Lets the user pick a subscription list file, check the feeds they want from it,
/// and add them to a folder or to an account root.
/// Unlike File > Import Subscriptions, this does not recreate the file's folder structure.
@MainActor final class ImportSubscriptionsController: NSObject {

  private let hostWindow: NSWindow
  private let presenter: SubscriptionSheetPresenter
  private let initialContainer: Container?
  private var importedFeeds = [ImportedFeed]()
  private var sheetWindow: NSWindow?

  private let checklistView = FeedChecklistView()
  private let folderPopUpButton = NSPopUpButton()
  private lazy var importButton = NSButton(title: NSLocalizedString("Import", comment: "Import subscriptions"), target: self, action: #selector(importSelectedFeeds(_:)))

  init(hostWindow: NSWindow, initialContainer: Container?) {
    self.hostWindow = hostWindow
    self.presenter = SubscriptionSheetPresenter(hostWindow: hostWindow)
    self.initialContainer = initialContainer
  }

  // MARK: - API

  func start() {
    let panel = NSOpenPanel()
    panel.canDownloadUbiquitousContents = true
    panel.canResolveUbiquitousConflicts = true
    panel.canChooseFiles = true
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = false
    panel.resolvesAliases = true
    panel.allowedContentTypes = [UTType.opml, .xml, .propertyList, .json, .plainText, .html]
    panel.allowsOtherFileTypes = true
    panel.message = NSLocalizedString("Choose an OPML, NetNewsWire 3, JSON, text, or HTML subscription list.", comment: "Import subscriptions")

    panel.beginSheetModal(for: hostWindow) { [weak self] response in
      guard response == .OK, let fileURL = panel.url else {
        return
      }
      self?.showFeedPicker(for: fileURL)
    }
  }

  // MARK: - Actions

  @objc private func folderDidChange(_ sender: Any?) {
    updateImportButton()
  }

  @objc private func cancel(_ sender: Any?) {
    endSheet(.cancel)
  }

  @objc private func importSelectedFeeds(_ sender: Any?) {
    guard let container = selectedContainer(), let account = container.account else {
      return
    }
    let selectedFeedSpecifiers = checklistView.selectedIndexes.map { importedFeeds[$0].feedSpecifier }
    AddFeedDefaultContainer.saveDefaultContainer(container)
    endSheet(.OK)

    Task { @MainActor in
      do {
        try await account.addOPMLFeeds(selectedFeedSpecifiers, to: container)
      } catch {
        NSApplication.shared.presentError(error)
      }
    }
  }
}

// MARK: - Private

private extension ImportSubscriptionsController {

  func showFeedPicker(for fileURL: URL) {
    do {
      importedFeeds = try SubscriptionListParser.parse(fileURL: fileURL)
    } catch {
      NSApplication.shared.presentError(error)
      return
    }

    checklistView.rows = importedFeeds.map { FeedChecklistRow(title: $0.feedSpecifier.title ?? $0.feedSpecifier.feedURL, folderName: $0.folderName, url: $0.feedSpecifier.feedURL) }
    let window = makeSheetWindow(fileName: fileURL.lastPathComponent)
    sheetWindow = window
    presenter.present(window)
  }

  func makeSheetWindow(fileName: String) -> NSWindow {
    let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: presenter.preferredWidth, height: 460), styleMask: [.titled], backing: .buffered, defer: false)
    window.title = NSLocalizedString("Import Feeds", comment: "Import subscriptions")

    let formatString = NSLocalizedString("Choose the feeds to add from “%@”.", comment: "Import subscriptions")
    let headerLabel = NSTextField(labelWithString: String(format: formatString, fileName))
    headerLabel.lineBreakMode = .byTruncatingMiddle

    checklistView.selectionDidChange = { [weak self] in
      self?.updateImportButton()
    }

    configureFolderPopUpButton()
    let folderLabel = NSTextField(labelWithString: NSLocalizedString("Add to:", comment: "Import subscriptions"))
    let folderRow = NSStackView(views: [folderLabel, folderPopUpButton])
    folderPopUpButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 240).isActive = true

    let cancelButton = NSButton(title: NSLocalizedString("Cancel", comment: "Import subscriptions"), target: self, action: #selector(cancel(_:)))
    cancelButton.keyEquivalent = "\u{1b}"
    importButton.keyEquivalent = "\r"
    let buttonRow = NSStackView()
    buttonRow.addView(cancelButton, in: .trailing)
    buttonRow.addView(importButton, in: .trailing)

    let contentStack = NSStackView(views: [headerLabel, checklistView, folderRow, buttonRow])
    contentStack.orientation = .vertical
    contentStack.alignment = .leading
    contentStack.spacing = 12
    contentStack.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
    window.contentView = contentStack
    // ponytail: NSStackView's .width alignment did not stretch the checklist, so pin each row's width by hand.
    for arrangedView in contentStack.arrangedSubviews {
      arrangedView.widthAnchor.constraint(equalTo: contentStack.widthAnchor, constant: -40).isActive = true
    }

    updateImportButton()
    return window
  }

  func configureFolderPopUpButton() {
    let folderTreeController = TreeController(delegate: FolderTreeControllerDelegate())
    folderPopUpButton.menu = FolderTreeMenu.createFolderPopupMenu(with: folderTreeController.rootNode)
    folderPopUpButton.target = self
    folderPopUpButton.action = #selector(folderDidChange(_:))

    let preferredContainer = initialContainer ?? AddFeedDefaultContainer.defaultContainer
    if let preferredContainer, let account = preferredContainer.account {
      FolderTreeMenu.select(account: account, folder: preferredContainer as? Folder, in: folderPopUpButton)
    }
  }

  func selectedContainer() -> Container? {
    guard let selectedItem = folderPopUpButton.selectedItem, selectedItem.isEnabled else {
      return nil
    }
    return selectedItem.representedObject as? Container
  }

  func updateImportButton() {
    importButton.isEnabled = selectedContainer() != nil && checklistView.hasSelection
  }

  func endSheet(_ response: NSApplication.ModalResponse) {
    guard let sheetWindow else {
      return
    }
    presenter.dismiss(sheetWindow, response: response)
    self.sheetWindow = nil
  }
}
