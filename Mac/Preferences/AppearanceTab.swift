//
//  AppearanceTab.swift
//  NetNewsWire
//
//  Created by Jeong-Un Kim on 10/29/26.
//  Copyright © 2026 Ranchero Software. All rights reserved.
//

import AppKit
import SwiftUI

/// Where a font family and its sizes are stored. The Fonts panel changes the family and the first size.
@MainActor private enum FontSlot {
  case sidebar, timeline, article

  var family: String? {
    get {
      switch self {
      case .sidebar: AppDefaults.sidebarFontFamily
      case .timeline: AppDefaults.timelineFontFamily
      case .article: AppDefaults.articleFontFamily
      }
    }
    nonmutating set {
      switch self {
      case .sidebar: AppDefaults.sidebarFontFamily = newValue
      case .timeline: AppDefaults.timelineFontFamily = newValue
      case .article: AppDefaults.articleFontFamily = newValue
      }
    }
  }

  /// The exact face from the Fonts panel; nil means the family's regular face.
  var fontName: String? {
    get {
      switch self {
      case .sidebar: AppDefaults.sidebarFontName
      case .timeline: AppDefaults.timelineFontName
      case .article: AppDefaults.articleFontName
      }
    }
    nonmutating set {
      switch self {
      case .sidebar: AppDefaults.sidebarFontName = newValue
      case .timeline: AppDefaults.timelineFontName = newValue
      case .article: AppDefaults.articleFontName = newValue
      }
    }
  }

  /// What the row shows: the face's display name ("Noto Sans KR Bold"), else the family.
  var displayName: String? {
    fontName.flatMap { NSFont(name: $0, size: NSFont.systemFontSize)?.displayName } ?? family
  }

  /// The size the Fonts panel edits; 0 stored means the default.
  var panelSize: CGFloat {
    get {
      switch self {
      case .sidebar: AppDefaults.sidebarFontPointSize
      case .timeline: AppDefaults.timelineTitleFontPointSize
      case .article: AppDefaults.articleBodyFontPointSize
      }
    }
    nonmutating set {
      switch self {
      case .sidebar: AppDefaults.sidebarFontPointSize = newValue
      case .timeline: AppDefaults.timelineTitleFontPointSize = newValue
      case .article: AppDefaults.articleBodyFontPointSize = newValue
      }
    }
  }

  var defaultPanelSize: CGFloat {
    switch self {
    case .sidebar: AppearanceTab.defaultSidebarFontPointSize
    case .timeline: AppDefaults.actualFontSize(for: AppDefaults.timelineFontSize)
    case .article: AppearanceTab.defaultArticleBodyPointSize
    }
  }

  var defaultFamilyTitle: LocalizedStringKey {
    self == .article ? "Theme Default" : "System Font"
  }

  var resetTitle: LocalizedStringKey {
    self == .article ? "Use Default" : "Use System Font"
  }

  /// The font the Fonts panel starts from.
  var currentFont: NSFont {
    AppDefaults.font(familyName: family, fontName: fontName, size: panelSize > 0 ? panelSize : defaultPanelSize)
  }

  func reset() {
    family = nil
    fontName = nil
    switch self {
    case .sidebar:
      AppDefaults.sidebarFontPointSize = 0
    case .timeline:
      AppDefaults.timelineTitleFontPointSize = 0
      AppDefaults.timelineSummaryFontPointSize = 0
    case .article:
      AppDefaults.articleBodyFontPointSize = 0
      AppDefaults.articleTitleFontPointSize = 0
    }
  }
}

/// The Fonts panel's target: SwiftUI views are not in the responder chain, so the panel reports here.
@MainActor private final class FontPanelClient: NSObject, NSFontChanging {
  static let shared = FontPanelClient()
  private var slot = FontSlot.sidebar

  func show(_ slot: FontSlot) {
    self.slot = slot
    let fontManager = NSFontManager.shared
    fontManager.target = self
    fontManager.setSelectedFont(slot.currentFont, isMultiple: false)
    fontManager.orderFrontFontPanel(nil)
  }

  func changeFont(_ sender: NSFontManager?) {
    guard let sender else {
      return
    }
    let newFont = sender.convert(slot.currentFont)
    // The system font reports a private family name (".AppleSystemUIFont"); store that choice as "no family".
    slot.family = newFont.familyName.flatMap { $0.hasPrefix(".") ? nil : $0 }
    slot.fontName = slot.family == nil ? nil : newFont.fontName
    slot.panelSize = newFont.pointSize
  }

  func validModesForFontPanel(_ fontPanel: NSFontPanel) -> NSFontPanel.ModeMask {
    [.collection, .face, .size]
  }
}

struct AppearanceTab: View {
  @StateObject private var defaults = DefaultsChangeObserver()
  @State private var themeNamesRevision = 0

  static let defaultSidebarFontPointSize: CGFloat = 13
  // Matches the "Large" article text size class (18px) and the theme's 1.85rem title.
  static let defaultArticleBodyPointSize: CGFloat = 18
  static let defaultArticleTitlePointSize: CGFloat = 30

  var body: some View {
    Form {
      Section("Sidebar") {
        fontRow(.sidebar)
        sizeRow("Size", range: 10...24, defaultSize: Self.defaultSidebarFontPointSize,
                read: { AppDefaults.sidebarFontPointSize }, write: { AppDefaults.sidebarFontPointSize = $0 })
        SettingsCaption("The default size follows the sidebar icon size in System Settings. The Fonts panel sets the family and the size.")
        backgroundRow("Background Color", placeholder: .windowBackgroundColor,
                      read: { AppDefaults.sidebarBackgroundColor }, write: { AppDefaults.sidebarBackgroundColor = $0 })
        Toggle("Grayscale icons", isOn: Binding(
          get: { AppDefaults.sidebarIconsAreGrayscale },
          set: { AppDefaults.sidebarIconsAreGrayscale = $0 }))
        backgroundRow("Badge Text Color", placeholder: Assets.Colors.sidebarUnreadCountText,
                      read: { AppDefaults.sidebarBadgeTextColor }, write: { AppDefaults.sidebarBadgeTextColor = $0 })
        backgroundRow("Badge Background Color", placeholder: Assets.Colors.sidebarUnreadCountBackground,
                      read: { AppDefaults.sidebarBadgeBackgroundColor }, write: { AppDefaults.sidebarBadgeBackgroundColor = $0 })
      }

      Section("Article List") {
        fontRow(.timeline)
        sizeRow("Title Size", range: 10...24, defaultSize: FontSlot.timeline.defaultPanelSize,
                read: { AppDefaults.timelineTitleFontPointSize }, write: { AppDefaults.timelineTitleFontPointSize = $0 })
        sizeRow("Summary Size", range: 10...24, defaultSize: FontSlot.timeline.defaultPanelSize,
                read: { AppDefaults.timelineSummaryFontPointSize }, write: { AppDefaults.timelineSummaryFontPointSize = $0 })
        Toggle("Bold Title", isOn: Binding(
          get: { AppDefaults.timelineTitleIsBold },
          set: { AppDefaults.timelineTitleIsBold = $0 }))
        Toggle("Bold Summary", isOn: Binding(
          get: { AppDefaults.timelineSummaryIsBold },
          set: { AppDefaults.timelineSummaryIsBold = $0 }))
        SettingsCaption("The Fonts panel sets the family and the title size.")
        backgroundRow("Background Color", placeholder: .controlBackgroundColor,
                      read: { AppDefaults.timelineBackgroundColor }, write: { AppDefaults.timelineBackgroundColor = $0 })
        Toggle("Dim read articles", isOn: Binding(
          get: { AppDefaults.timelineDimsReadArticles },
          set: { AppDefaults.timelineDimsReadArticles = $0 }))
        sizeRow("Icon Size", range: Double(TimelineIconShape.minimumDimension)...Double(TimelineIconShape.maximumDimension), defaultSize: TimelineIconShape.defaultDimension,
                read: { AppDefaults.timelineIconDimension }, write: { AppDefaults.timelineIconDimension = $0 })
        LabeledContent("Icon Shape") {
          Picker("Icon Shape", selection: iconShapeBinding) {
            ForEach(TimelineIconShape.allCases, id: \.rawValue) { shape in
              Text(shape.title).tag(shape)
            }
          }
          .labelsHidden()
          .pickerStyle(.segmented)
        }
      }

      Section("Article View") {
        fontRow(.article)
        sizeRow("Body Size", range: 10...32, defaultSize: Self.defaultArticleBodyPointSize,
                read: { AppDefaults.articleBodyFontPointSize }, write: { AppDefaults.articleBodyFontPointSize = $0 })
        sizeRow("Title Size", range: 14...48, defaultSize: Self.defaultArticleTitlePointSize,
                read: { AppDefaults.articleTitleFontPointSize }, write: { AppDefaults.articleTitleFontPointSize = $0 })
        SettingsCaption("The Fonts panel sets the family and the body size.")
        backgroundRow("Background Color", placeholder: .textBackgroundColor,
                      read: { AppDefaults.articleBackgroundColor }, write: { AppDefaults.articleBackgroundColor = $0 })
        LabeledContent("Theme") {
          HStack {
            Picker("Theme", selection: themeBinding) {
              Text(ArticleTheme.defaultTheme.name).tag(ArticleTheme.defaultTheme.name)
              Divider()
              ForEach(ArticleThemesManager.shared.themeNames, id: \.self) { name in
                Text(name).tag(name)
              }
            }
            .labelsHidden()
            .frame(width: 180)
            Button("Open Themes Folder") {
              NSWorkspace.shared.open(URL(fileURLWithPath: ArticleThemesManager.shared.folderPath))
            }
          }
        }
        VStack(alignment: .leading, spacing: 6) {
          Toggle("Enable JavaScript", isOn: Binding(
            get: { AppDefaults.isArticleContentJavascriptEnabled },
            set: { AppDefaults.isArticleContentJavascriptEnabled = $0 }))
          SettingsCaption("Some content, such as videos and embedded social media posts, may require JavaScript to work correctly.")
        }
        Toggle("Show theme menu in the status bar", isOn: Binding(
          get: { AppDefaults.showStatusBarThemeMenu },
          set: { AppDefaults.showStatusBarThemeMenu = $0 }))
      }

      Section("Window") {
        backgroundRow("Border Color", placeholder: .separatorColor,
                      read: { AppDefaults.borderColor }, write: { AppDefaults.borderColor = $0 })
        SettingsCaption("The lines between the sidebar, article list, and article, and the status bar's lines.")
      }
    }
    .formStyle(.grouped)
    .onReceive(NotificationCenter.default.publisher(for: .ArticleThemeNamesDidChangeNotification)) { _ in
      themeNamesRevision += 1
    }
    .id(themeNamesRevision)
  }

  // MARK: - Rows

  private func fontRow(_ slot: FontSlot) -> some View {
    LabeledContent("Font") {
      HStack {
        (slot.displayName.map { Text(verbatim: $0) } ?? Text(slot.defaultFamilyTitle))
          .font(Font(AppDefaults.font(familyName: slot.family, fontName: slot.fontName, size: NSFont.systemFontSize)))
          .lineLimit(1)
          .frame(maxWidth: .infinity, alignment: .leading)
        Button("Choose…") {
          FontPanelClient.shared.show(slot)
        }
        Button(slot.resetTitle) {
          slot.reset()
        }
      }
    }
  }

  /// A slider over a stored size where 0 means "default"; the label shows the stored size or "Default".
  private func sizeRow(_ title: LocalizedStringKey, range: ClosedRange<Double>, defaultSize: CGFloat,
                       read: @escaping () -> CGFloat, write: @escaping (CGFloat) -> Void) -> some View {
    let stored = read()
    let binding = Binding<Double>(
      get: { Double(stored > 0 ? stored : defaultSize) },
      set: { write(CGFloat($0.rounded())) })
    return LabeledContent(title) {
      HStack {
        Slider(value: binding, in: range, step: 1)
        Group {
          if stored > 0 {
            Text("\(Int(stored)) pt")
          } else {
            Text("Default")
          }
        }
        .foregroundStyle(.secondary)
        .frame(width: 60, alignment: .trailing)
      }
    }
  }

  /// The SwiftUI color picker with its label, so the popover is titled after it, and a reset beside it.
  private func backgroundRow(_ title: LocalizedStringKey, placeholder: NSColor,
                             read: @escaping () -> NSColor?, write: @escaping (NSColor?) -> Void) -> some View {
    HStack(spacing: 12) {
      ColorPicker(title, selection: Binding(
        get: { Color(nsColor: read() ?? placeholder) },
        set: { write(NSColor($0)) }))
      Button("Use Default") {
        write(nil)
      }
    }
  }

  private var iconShapeBinding: Binding<TimelineIconShape> {
    Binding(get: { AppDefaults.timelineIconShape }, set: { AppDefaults.timelineIconShape = $0 })
  }

  private var themeBinding: Binding<String> {
    Binding(get: { ArticleThemesManager.shared.currentThemeName }, set: { ArticleThemesManager.shared.currentThemeName = $0 })
  }
}
