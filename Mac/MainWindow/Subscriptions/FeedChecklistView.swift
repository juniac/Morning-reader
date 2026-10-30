//
//  FeedChecklistView.swift
//  NetNewsWire
//
//  Created by Jeong-Un Kim on 10/29/26.
//  Copyright © 2026 Ranchero Software. All rights reserved.
//

import AppKit

struct FeedChecklistRow {
  let title: String
  let folderName: String?
  let url: String
  var isSelected = true
}

/// A table of feeds with a checkbox per row plus Select All / Select None, shared by the import and export sheets.
@MainActor final class FeedChecklistView: NSView {

  private enum ColumnIdentifier {
    static let selected = NSUserInterfaceItemIdentifier("selected")
    static let title = NSUserInterfaceItemIdentifier("title")
    static let folder = NSUserInterfaceItemIdentifier("folder")
    static let url = NSUserInterfaceItemIdentifier("url")
  }

  var rows = [FeedChecklistRow]() {
    didSet {
      // A checkbox click already updated its own cell; reloading would recreate every cell view.
      if !isTogglingSingleRow {
        tableView.reloadData()
      }
      selectionDidChange?()
    }
  }

  private var isTogglingSingleRow = false

  var selectionDidChange: (() -> Void)?

  var selectedIndexes: IndexSet {
    IndexSet(rows.indices.filter { rows[$0].isSelected })
  }

  var hasSelection: Bool {
    rows.contains(where: \.isSelected)
  }

  private let tableView = NSTableView()

  init() {
    super.init(frame: .zero)
    translatesAutoresizingMaskIntoConstraints = false
    configureTableView()

    let scrollView = NSScrollView()
    scrollView.documentView = tableView
    scrollView.hasVerticalScroller = true
    scrollView.borderType = .bezelBorder
    scrollView.heightAnchor.constraint(greaterThanOrEqualToConstant: 240).isActive = true

    let selectAllButton = NSButton(title: NSLocalizedString("Select All", comment: "Feed checklist"), target: self, action: #selector(selectAllRows(_:)))
    let selectNoneButton = NSButton(title: NSLocalizedString("Select None", comment: "Feed checklist"), target: self, action: #selector(selectNoRows(_:)))
    let buttonRow = NSStackView(views: [selectAllButton, selectNoneButton])

    let stackView = NSStackView(views: [scrollView, buttonRow])
    stackView.orientation = .vertical
    stackView.alignment = .leading
    stackView.spacing = 8
    stackView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(stackView)
    NSLayoutConstraint.activate([
      stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
      stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
      stackView.topAnchor.constraint(equalTo: topAnchor),
      stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
      scrollView.widthAnchor.constraint(equalTo: stackView.widthAnchor)
    ])
  }

  required init?(coder: NSCoder) {
    return nil
  }

  // MARK: - Actions

  @objc private func selectAllRows(_ sender: Any?) {
    setAllRows(selected: true)
  }

  @objc private func selectNoRows(_ sender: Any?) {
    setAllRows(selected: false)
  }

  @objc private func toggleRow(_ sender: NSButton) {
    let row = tableView.row(for: sender)
    guard row >= 0 else {
      return
    }
    isTogglingSingleRow = true
    rows[row].isSelected = sender.state == .on
    isTogglingSingleRow = false
  }
}

// MARK: - NSTableViewDataSource, NSTableViewDelegate

extension FeedChecklistView: NSTableViewDataSource, NSTableViewDelegate {

  func numberOfRows(in tableView: NSTableView) -> Int {
    rows.count
  }

  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    guard let tableColumn else {
      return nil
    }
    let checklistRow = rows[row]

    if tableColumn.identifier == ColumnIdentifier.selected {
      let checkbox = (tableView.makeView(withIdentifier: ColumnIdentifier.selected, owner: self) as? NSButton) ?? makeCheckbox()
      checkbox.state = checklistRow.isSelected ? .on : .off
      return checkbox
    }

    let text: String
    switch tableColumn.identifier {
    case ColumnIdentifier.title:
      text = checklistRow.title
    case ColumnIdentifier.folder:
      text = checklistRow.folderName ?? ""
    default:
      text = checklistRow.url
    }

    let label = (tableView.makeView(withIdentifier: tableColumn.identifier, owner: self) as? NSTextField) ?? makeLabel(identifier: tableColumn.identifier)
    label.stringValue = text
    label.toolTip = text
    return label
  }
}

// MARK: - Private

private extension FeedChecklistView {

  func configureTableView() {
    let selectedColumn = NSTableColumn(identifier: ColumnIdentifier.selected)
    selectedColumn.title = ""
    selectedColumn.width = 24
    selectedColumn.resizingMask = []

    let titleColumn = NSTableColumn(identifier: ColumnIdentifier.title)
    titleColumn.title = NSLocalizedString("Feed", comment: "Feed checklist")
    titleColumn.width = 200

    let folderColumn = NSTableColumn(identifier: ColumnIdentifier.folder)
    folderColumn.title = NSLocalizedString("Folder", comment: "Feed checklist")
    folderColumn.width = 100

    let urlColumn = NSTableColumn(identifier: ColumnIdentifier.url)
    urlColumn.title = NSLocalizedString("URL", comment: "Feed checklist")
    urlColumn.width = 160

    for column in [selectedColumn, titleColumn, folderColumn, urlColumn] {
      tableView.addTableColumn(column)
    }
    tableView.columnAutoresizingStyle = .uniformColumnAutoresizingStyle
    tableView.usesAlternatingRowBackgroundColors = true
    tableView.allowsEmptySelection = true
    tableView.dataSource = self
    tableView.delegate = self
  }

  func setAllRows(selected: Bool) {
    rows = rows.map { row in
      var row = row
      row.isSelected = selected
      return row
    }
  }

  func makeCheckbox() -> NSButton {
    let checkbox = NSButton(checkboxWithTitle: "", target: self, action: #selector(toggleRow(_:)))
    checkbox.identifier = ColumnIdentifier.selected
    return checkbox
  }

  func makeLabel(identifier: NSUserInterfaceItemIdentifier) -> NSTextField {
    let label = NSTextField(labelWithString: "")
    label.identifier = identifier
    label.lineBreakMode = .byTruncatingTail
    return label
  }
}
