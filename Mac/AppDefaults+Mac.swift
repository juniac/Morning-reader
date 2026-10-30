//
//  AppDefaults+Mac.swift
//  NetNewsWire
//
//  Created by Brent Simmons on 9/22/17.
//  Copyright © 2017 Ranchero Software. All rights reserved.
//

import AppKit

enum FontSize: Int {
	case small = 0
	case medium = 1
	case large = 2
	case veryLarge = 3
}

/// What the status bar’s count text shows. Clicking the text cycles through them.
/// How the feed icon is clipped in the article list.
enum TimelineIconShape: Int, CaseIterable {
  case original = 0
  case square = 1
  case rounded = 2
  case circle = 3

  static let defaultDimension: CGFloat = 48
  static let minimumDimension: CGFloat = 16
  static let maximumDimension: CGFloat = 64

  var title: String {
    switch self {
    case .original:
      NSLocalizedString("Original", comment: "Timeline icon shape")
    case .square:
      NSLocalizedString("Square", comment: "Timeline icon shape")
    case .rounded:
      NSLocalizedString("Rounded", comment: "Timeline icon shape")
    case .circle:
      NSLocalizedString("Circle", comment: "Timeline icon shape")
    }
  }

  /// Original shows the image as-is: no clipping and no background box behind it.
  var drawsBackground: Bool {
    self != .original
  }

  func cornerRadius(forDimension dimension: CGFloat) -> CGFloat {
    switch self {
    case .original, .square:
      0
    case .rounded:
      (dimension * 0.2).rounded()
    case .circle:
      dimension / 2
    }
  }
}

/// Which articles the article list shows. One setting for every feed; it survives relaunch.
enum TimelineFilter: Int, CaseIterable {
  case starred = 0
  case unread = 1
  case all = 2

  var title: String {
    switch self {
    case .starred:
      NSLocalizedString("Starred", comment: "Timeline filter")
    case .unread:
      NSLocalizedString("Unread", comment: "Timeline filter")
    case .all:
      NSLocalizedString("All", comment: "Timeline filter")
    }
  }
}

enum StatusBarCountMode: Int {
	case unreadCount = 0
	case foldersAndFeeds = 1
	case lastRefresh = 2

	/// The mode after this one when clicking. Skips the unread count when unread counts are hidden.
	func next(includingUnreadCount: Bool) -> StatusBarCountMode {
		switch self {
		case .lastRefresh:
			includingUnreadCount ? .unreadCount : .foldersAndFeeds
		case .unreadCount:
			.foldersAndFeeds
		case .foldersAndFeeds:
			.lastRefresh
		}
	}
}

extension AppDefaults.Key {
	static let legacyWindowState = "windowState"
	static let secureWindowState = "secureWindowState"
	static let sidebarFontSize = "sidebarFontSize"
	static let timelineFontSize = "timelineFontSize"
	static let useColumnLayout = "useColumnLayout"
	static let showStatusBar = "showStatusBar"
	static let showStatusBarThemeMenu = "showStatusBarThemeMenu"
	static let statusBarCountMode = "statusBarCountMode"
	static let detailFontSize = "detailFontSize"
	static let openInBrowserInBackground = "openInBrowserInBackground"
	static let subscribeToFeedsInDefaultBrowser = "subscribeToFeedsInDefaultBrowser"
	static let articleTextSize = "articleTextSize"
	static let refreshInterval = "refreshInterval"
	static let importOPMLAccountID = "importOPMLAccountID"
	static let exportOPMLAccountID = "exportOPMLAccountID"
	static let defaultBrowserID = "defaultBrowserID"
  static let showAppIconUnreadCountBadge = "showAppIconUnreadCountBadge"
  static let confirmMarkAllAsRead = "confirmMarkAllAsRead"
  static let sidebarFontFamily = "sidebarFontFamily"
  static let sidebarFontPointSize = "sidebarFontPointSize"
  static let sidebarFontName = "sidebarFontName"
  static let timelineFontName = "timelineFontName"
  static let articleFontName = "articleFontName"
  static let articleFontFamily = "articleFontFamily"
  static let timelineIconDimension = "timelineIconDimension"
  static let timelineIconShape = "timelineIconShape"
  static let timelineTitleIsBold = "timelineTitleIsBold"
  static let timelineSummaryIsBold = "timelineSummaryIsBold"
  static let timelineDimsReadArticles = "timelineDimsReadArticles"
  static let sidebarIconsAreGrayscale = "sidebarIconsAreGrayscale"
  static let timelineFilter = "timelineFilter"
  static let timelineFontFamily = "timelineFontFamily"
  static let timelineTitleFontPointSize = "timelineTitleFontPointSize"
  static let timelineSummaryFontPointSize = "timelineSummaryFontPointSize"
  static let articleTitleFontPointSize = "articleTitleFontPointSize"
  static let articleBodyFontPointSize = "articleBodyFontPointSize"
  static let sidebarBackgroundColor = "sidebarBackgroundColor"
  static let timelineBackgroundColor = "timelineBackgroundColor"
  static let articleBackgroundColor = "articleBackgroundColor"
  static let borderColor = "borderColor"
  static let sidebarBadgeTextColor = "sidebarBadgeTextColor"
  static let sidebarBadgeBackgroundColor = "sidebarBadgeBackgroundColor"

	// Hidden prefs
	static let showDebugMenu = "ShowDebugMenu"
	static let timelineShowsSeparators = "CorreiaSeparators"
	static let showTitleOnMainWindow = "KafasisTitleMode"
	static let feedDoubleClickMarkAsRead = "GruberFeedDoubleClickMarkAsRead"
	static let suppressSyncOnLaunch = "DevroeSuppressSyncOnLaunch"
	static let webInspectorEnabled = "WebInspectorEnabled"
	static let webInspectorStartsAttached = "__WebInspectorPageGroupLevel1__.WebKit2InspectorStartsAttached"
}

extension AppDefaults {

	private static let smallestFontSizeRawValue = FontSize.small.rawValue
	private static let largestFontSizeRawValue = FontSize.veryLarge.rawValue

	/// Stores window state prior to switching to secure state restoration.
	///
	/// This is referenced temporarily, only to be able to provide migration from legacy to secure window state.
	/// TODO: delete for NetNewsWire 7.
	static var legacyWindowState: [AnyHashable: Any]? {
		UserDefaults.standard.object(forKey: Key.legacyWindowState) as? [AnyHashable: Any]
	}

	static func deleteLegacyWindowState() {
		UserDefaults.standard.removeObject(forKey: Key.legacyWindowState)
	}

	static var secureWindowState: Data? {
		get {
			UserDefaults.standard.object(forKey: Key.secureWindowState) as? Data
		}
		set {
			UserDefaults.standard.set(newValue, forKey: Key.secureWindowState)
		}
	}

	static var openInBrowserInBackground: Bool {
		get {
			UserDefaults.standard.bool(forKey: Key.openInBrowserInBackground)
		}
		set {
			UserDefaults.standard.set(newValue, forKey: Key.openInBrowserInBackground)
		}
	}

	// Special case for this default: store/retrieve it from the shared app group
	// defaults, so that it can be resolved by the Safari App Extension.
	static var subscribeToFeedDefaults: UserDefaults {
		if let appGroupID = Bundle.main.object(forInfoDictionaryKey: "AppGroup") as? String,
		   let appGroupDefaults = UserDefaults(suiteName: appGroupID) {
			appGroupDefaults
		} else {
			UserDefaults.standard
		}
	}

	static var subscribeToFeedsInDefaultBrowser: Bool {
		get {
			subscribeToFeedDefaults.bool(forKey: Key.subscribeToFeedsInDefaultBrowser)
		}
		set {
			subscribeToFeedDefaults.set(newValue, forKey: Key.subscribeToFeedsInDefaultBrowser)
		}
	}

	static var sidebarFontSize: FontSize {
		get {
			fontSize(for: Key.sidebarFontSize)
		}
		set {
			AppDefaults.setFontSize(for: Key.sidebarFontSize, newValue)
		}
	}

	static var timelineFontSize: FontSize {
		get {
			fontSize(for: Key.timelineFontSize)
		}
		set {
			AppDefaults.setFontSize(for: Key.timelineFontSize, newValue)
		}
	}

	static var detailFontSize: FontSize {
		get {
			fontSize(for: Key.detailFontSize)
		}
		set {
			AppDefaults.setFontSize(for: Key.detailFontSize, newValue)
		}
	}

	static var importOPMLAccountID: String? {
		get {
			UserDefaults.standard.string(forKey: Key.importOPMLAccountID)
		}
		set {
			UserDefaults.standard.set(newValue, forKey: Key.importOPMLAccountID)
		}
	}

	static var exportOPMLAccountID: String? {
		get {
			UserDefaults.standard.string(forKey: Key.exportOPMLAccountID)
		}
		set {
			UserDefaults.standard.set(newValue, forKey: Key.exportOPMLAccountID)
		}
	}

	static var defaultBrowserID: String? {
		get {
			UserDefaults.standard.string(forKey: Key.defaultBrowserID)
		}
		set {
			UserDefaults.standard.set(newValue, forKey: Key.defaultBrowserID)
		}
	}

	static var showTitleOnMainWindow: Bool {
		UserDefaults.standard.bool(forKey: Key.showTitleOnMainWindow)
	}

	static var showDebugMenu: Bool {
		UserDefaults.standard.bool(forKey: Key.showDebugMenu)
	}

	static var feedDoubleClickMarkAsRead: Bool {
		get {
			UserDefaults.standard.bool(forKey: Key.feedDoubleClickMarkAsRead)
		}
		set {
			UserDefaults.standard.set(newValue, forKey: Key.feedDoubleClickMarkAsRead)
		}
	}

	static var suppressSyncOnLaunch: Bool {
		get {
			UserDefaults.standard.bool(forKey: Key.suppressSyncOnLaunch)
		}
		set {
			UserDefaults.standard.set(newValue, forKey: Key.suppressSyncOnLaunch)
		}
	}

	static var webInspectorEnabled: Bool {
		get {
			UserDefaults.standard.bool(forKey: Key.webInspectorEnabled)
		}
		set {
			UserDefaults.standard.set(newValue, forKey: Key.webInspectorEnabled)
		}
	}

	static var webInspectorStartsAttached: Bool {
		get {
			UserDefaults.standard.bool(forKey: Key.webInspectorStartsAttached)
		}
		set {
			UserDefaults.standard.set(newValue, forKey: Key.webInspectorStartsAttached)
		}
	}

	// Sorting is per window and lives in TimelineWindowState. These two are read-only seeds
	// for a window that has no saved sort, so a setting from before per-window sorting carries over.
	static var timelineSortDirection: ComparisonResult {
		AppDefaults.sortDirection(for: Key.timelineSortDirection)
	}

	static var timelineGroupByFeed: Bool {
		UserDefaults.standard.bool(forKey: Key.timelineGroupByFeed)
	}

	/// Column layout: multi-column timeline table with the article view below it, like Mail’s View > Use Column Layout. Applies to all windows.
	static var useColumnLayout: Bool {
		get {
			UserDefaults.standard.bool(forKey: Key.useColumnLayout)
		}
		set {
			UserDefaults.standard.set(newValue, forKey: Key.useColumnLayout)
		}
	}

	/// The main window status bar. Applies to all windows.
	static var showStatusBar: Bool {
		get {
			UserDefaults.standard.bool(forKey: Key.showStatusBar)
		}
		set {
			UserDefaults.standard.set(newValue, forKey: Key.showStatusBar)
		}
	}

	/// The status bar is off by default on macOS 26 and on by default everywhere else.
	private static var showStatusBarDefault: Bool {
		if #available(macOS 27.0, *) {
			return true
		}
		if #available(macOS 26.0, *) {
			return false
		}
		return true
	}

	static var showStatusBarThemeMenu: Bool {
		get {
			UserDefaults.standard.bool(forKey: Key.showStatusBarThemeMenu)
		}
		set {
			UserDefaults.standard.set(newValue, forKey: Key.showStatusBarThemeMenu)
		}
	}

	static var statusBarCountMode: StatusBarCountMode {
		get {
			StatusBarCountMode(rawValue: UserDefaults.standard.integer(forKey: Key.statusBarCountMode)) ?? .lastRefresh
		}
		set {
			UserDefaults.standard.set(newValue.rawValue, forKey: Key.statusBarCountMode)
		}
	}

	static var timelineShowsSeparators: Bool {
		UserDefaults.standard.bool(forKey: Key.timelineShowsSeparators)
	}

	static var articleTextSize: ArticleTextSize {
		get {
			let rawValue = UserDefaults.standard.integer(forKey: Key.articleTextSize)
			return ArticleTextSize(rawValue: rawValue) ?? ArticleTextSize.large
		}
		set {
			UserDefaults.standard.set(newValue.rawValue, forKey: Key.articleTextSize)
		}
	}

  static var showAppIconUnreadCountBadge: Bool {
    get {
      UserDefaults.standard.bool(forKey: Key.showAppIconUnreadCountBadge)
    }
    set {
      UserDefaults.standard.set(newValue, forKey: Key.showAppIconUnreadCountBadge)
    }
  }

  static var confirmMarkAllAsRead: Bool {
    get {
      UserDefaults.standard.bool(forKey: Key.confirmMarkAllAsRead)
    }
    set {
      UserDefaults.standard.set(newValue, forKey: Key.confirmMarkAllAsRead)
    }
  }

  /// A font family name; nil means the system font.
  static var sidebarFontFamily: String? {
    get {
      fontFamily(for: Key.sidebarFontFamily)
    }
    set {
      UserDefaults.standard.set(newValue, forKey: Key.sidebarFontFamily)
    }
  }

  /// 0 means the size that goes with the system sidebar icon size setting.
  static var sidebarFontPointSize: CGFloat {
    get {
      CGFloat(UserDefaults.standard.double(forKey: Key.sidebarFontPointSize))
    }
    set {
      UserDefaults.standard.set(Double(newValue), forKey: Key.sidebarFontPointSize)
    }
  }

  /// PostScript names of the exact faces picked in the Fonts panel, so the chosen weight and style
  /// apply too; nil means the family's regular face (or the system font when the family is nil).
  static var sidebarFontName: String? {
    get {
      fontFamily(for: Key.sidebarFontName)
    }
    set {
      UserDefaults.standard.set(newValue, forKey: Key.sidebarFontName)
    }
  }

  static var timelineFontName: String? {
    get {
      fontFamily(for: Key.timelineFontName)
    }
    set {
      UserDefaults.standard.set(newValue, forKey: Key.timelineFontName)
    }
  }

  static var articleFontName: String? {
    get {
      fontFamily(for: Key.articleFontName)
    }
    set {
      UserDefaults.standard.set(newValue, forKey: Key.articleFontName)
    }
  }

  /// A font family name for article content; nil means the theme's own font.
  static var articleFontFamily: String? {
    get {
      fontFamily(for: Key.articleFontFamily)
    }
    set {
      UserDefaults.standard.set(newValue, forKey: Key.articleFontFamily)
    }
  }

  /// Width and height, in points, of the feed icon in the article list.
  static var timelineIconDimension: CGFloat {
    get {
      let dimension = CGFloat(UserDefaults.standard.double(forKey: Key.timelineIconDimension))
      return dimension > 0 ? dimension : TimelineIconShape.defaultDimension
    }
    set {
      UserDefaults.standard.set(Double(newValue), forKey: Key.timelineIconDimension)
    }
  }

  static var timelineFilter: TimelineFilter {
    get {
      TimelineFilter(rawValue: UserDefaults.standard.integer(forKey: Key.timelineFilter)) ?? .all
    }
    set {
      UserDefaults.standard.set(newValue.rawValue, forKey: Key.timelineFilter)
    }
  }

  /// A font family name for the article list; nil means the system font.
  static var timelineFontFamily: String? {
    get {
      fontFamily(for: Key.timelineFontFamily)
    }
    set {
      UserDefaults.standard.set(newValue, forKey: Key.timelineFontFamily)
    }
  }

  /// 0 means the built-in size.
  static var timelineTitleFontPointSize: CGFloat {
    get {
      CGFloat(UserDefaults.standard.double(forKey: Key.timelineTitleFontPointSize))
    }
    set {
      UserDefaults.standard.set(Double(newValue), forKey: Key.timelineTitleFontPointSize)
    }
  }

  /// 0 means the built-in size.
  static var timelineSummaryFontPointSize: CGFloat {
    get {
      CGFloat(UserDefaults.standard.double(forKey: Key.timelineSummaryFontPointSize))
    }
    set {
      UserDefaults.standard.set(Double(newValue), forKey: Key.timelineSummaryFontPointSize)
    }
  }

  /// 0 means the theme's own title size.
  static var articleTitleFontPointSize: CGFloat {
    get {
      CGFloat(UserDefaults.standard.double(forKey: Key.articleTitleFontPointSize))
    }
    set {
      UserDefaults.standard.set(Double(newValue), forKey: Key.articleTitleFontPointSize)
    }
  }

  /// 0 means the Article Text Size setting decides.
  static var articleBodyFontPointSize: CGFloat {
    get {
      CGFloat(UserDefaults.standard.double(forKey: Key.articleBodyFontPointSize))
    }
    set {
      UserDefaults.standard.set(Double(newValue), forKey: Key.articleBodyFontPointSize)
    }
  }

  /// nil means the system sidebar background.
  static var sidebarBackgroundColor: NSColor? {
    get {
      color(for: Key.sidebarBackgroundColor)
    }
    set {
      UserDefaults.standard.set(newValue?.hexString, forKey: Key.sidebarBackgroundColor)
    }
  }

  /// nil means the system list background.
  static var timelineBackgroundColor: NSColor? {
    get {
      color(for: Key.timelineBackgroundColor)
    }
    set {
      UserDefaults.standard.set(newValue?.hexString, forKey: Key.timelineBackgroundColor)
    }
  }

  /// nil means the theme's own page background.
  static var articleBackgroundColor: NSColor? {
    get {
      color(for: Key.articleBackgroundColor)
    }
    set {
      UserDefaults.standard.set(newValue?.hexString, forKey: Key.articleBackgroundColor)
    }
  }

  /// The split view dividers and status bar lines; nil means the system colors.
  static var borderColor: NSColor? {
    get {
      color(for: Key.borderColor)
    }
    set {
      UserDefaults.standard.set(newValue?.hexString, forKey: Key.borderColor)
    }
  }

  /// The sidebar unread count capsule; nil means the asset catalog colors.
  static var sidebarBadgeTextColor: NSColor? {
    get {
      color(for: Key.sidebarBadgeTextColor)
    }
    set {
      UserDefaults.standard.set(newValue?.hexString, forKey: Key.sidebarBadgeTextColor)
    }
  }

  static var sidebarBadgeBackgroundColor: NSColor? {
    get {
      color(for: Key.sidebarBadgeBackgroundColor)
    }
    set {
      UserDefaults.standard.set(newValue?.hexString, forKey: Key.sidebarBadgeBackgroundColor)
    }
  }

  private static func color(for key: String) -> NSColor? {
    UserDefaults.standard.string(forKey: key).flatMap { NSColor(hexString: $0) }
  }

  static var timelineTitleIsBold: Bool {
    get {
      UserDefaults.standard.bool(forKey: Key.timelineTitleIsBold)
    }
    set {
      UserDefaults.standard.set(newValue, forKey: Key.timelineTitleIsBold)
    }
  }

  static var timelineSummaryIsBold: Bool {
    get {
      UserDefaults.standard.bool(forKey: Key.timelineSummaryIsBold)
    }
    set {
      UserDefaults.standard.set(newValue, forKey: Key.timelineSummaryIsBold)
    }
  }

  /// Feed, folder, and smart feed icons in the sidebar drawn without color.
  static var sidebarIconsAreGrayscale: Bool {
    get {
      UserDefaults.standard.bool(forKey: Key.sidebarIconsAreGrayscale)
    }
    set {
      UserDefaults.standard.set(newValue, forKey: Key.sidebarIconsAreGrayscale)
    }
  }

  /// Read articles draw their text at reduced opacity in the article list.
  static var timelineDimsReadArticles: Bool {
    get {
      UserDefaults.standard.bool(forKey: Key.timelineDimsReadArticles)
    }
    set {
      UserDefaults.standard.set(newValue, forKey: Key.timelineDimsReadArticles)
    }
  }

  static var timelineIconShape: TimelineIconShape {
    get {
      TimelineIconShape(rawValue: UserDefaults.standard.integer(forKey: Key.timelineIconShape)) ?? .rounded
    }
    set {
      UserDefaults.standard.set(newValue.rawValue, forKey: Key.timelineIconShape)
    }
  }

  /// Resolves a stored family name to a font, falling back to the system font when the family is unset or not installed.
  static func font(familyName: String?, fontName: String? = nil, size: CGFloat, weight: NSFont.Weight = .regular) -> NSFont {
    // An exact face wins: it carries the weight and style the user picked.
    if let fontName, let font = NSFont(name: fontName, size: size) {
      return font
    }
    // NSFontManager weights: 5 is regular, 8 is semibold, 9 is bold.
    let managerWeight = weight == .bold ? 9 : weight == .semibold ? 8 : 5
    guard let familyName, !familyName.isEmpty,
        let font = NSFontManager.shared.font(withFamily: familyName, traits: [], weight: managerWeight, size: size) else {
      return NSFont.systemFont(ofSize: size, weight: weight)
    }
    return font
  }

  private static func fontFamily(for key: String) -> String? {
    guard let familyName = UserDefaults.standard.string(forKey: key), !familyName.isEmpty else {
      return nil
    }
    return familyName
  }

	static var refreshInterval: RefreshInterval {
		get {
			let rawValue = UserDefaults.standard.integer(forKey: Key.refreshInterval)
			if rawValue == 2 { // Old every-10-minutes setting — now using 30 minutes as minimum.
				return .every30Minutes
			}
			return RefreshInterval(rawValue: rawValue) ?? .every2Hours
		}
		set {
			UserDefaults.standard.set(newValue.rawValue, forKey: Key.refreshInterval)
		}
	}

	@MainActor static func registerDefaults() {
		// Migrate every-10-minute refresh interval to 30 minutes.
		let rawValue = UserDefaults.standard.integer(forKey: Key.refreshInterval)
		if rawValue == 2 {
			UserDefaults.standard.set(RefreshInterval.every30Minutes.rawValue, forKey: Key.refreshInterval)
		}

		#if DEBUG
 		let showDebugMenu = true
 		#else
 		let showDebugMenu = false
 		#endif

		let platformDefaults: [String: Any] = [
			Key.sidebarFontSize: FontSize.medium.rawValue,
			Key.timelineFontSize: FontSize.medium.rawValue,
			Key.detailFontSize: FontSize.medium.rawValue,
			Key.useColumnLayout: false,
			Key.showStatusBar: Self.showStatusBarDefault,
			Key.showStatusBarThemeMenu: true,
			Key.statusBarCountMode: StatusBarCountMode.lastRefresh.rawValue,
			"NSScrollViewShouldScrollUnderTitlebar": false,
			Key.refreshInterval: RefreshInterval.every2Hours.rawValue,
			Key.showDebugMenu: showDebugMenu,
      // The popup binding needs a registered value; the getter's fallback alone leaves it blank.
      Key.articleTextSize: ArticleTextSize.large.rawValue,
      Key.showAppIconUnreadCountBadge: true,
      Key.confirmMarkAllAsRead: true,
      Key.timelineIconDimension: Double(TimelineIconShape.defaultDimension),
      Key.timelineIconShape: TimelineIconShape.rounded.rawValue,
      Key.timelineFilter: TimelineFilter.all.rawValue,
      Key.timelineTitleIsBold: true
		]

		let defaults = commonRegisteredDefaults.merging(platformDefaults) { _, platformValue in platformValue }
		UserDefaults.standard.register(defaults: defaults)
	}

	static func actualFontSize(for fontSize: FontSize) -> CGFloat {
		switch fontSize {
		case .small:
			NSFont.systemFontSize
		case .medium:
			actualFontSize(for: .small) + 1.0
		case .large:
			actualFontSize(for: .medium) + 4.0
		case .veryLarge:
			actualFontSize(for: .large) + 8.0
		}
	}
}

private extension AppDefaults {

	static func fontSize(for key: String) -> FontSize {
		// Punted till after 1.0.
		.medium

//		var rawFontSize = UserDefaults.standard.integer(forKey: key)
//		if rawFontSize < smallestFontSizeRawValue {
//			rawFontSize = smallestFontSizeRawValue
//		}
//		if rawFontSize > largestFontSizeRawValue {
//			rawFontSize = largestFontSizeRawValue
//		}
//		return FontSize(rawValue: rawFontSize)!
	}

	static func setFontSize(for key: String, _ fontSize: FontSize) {
		UserDefaults.standard.set(fontSize.rawValue, forKey: key)
	}
}

extension NSColor {

  /// "#RRGGBB" in sRGB, or "#RRGGBBAA" when translucent. CSS reads the same string.
  var hexString: String? {
    guard let color = usingColorSpace(.sRGB) else {
      return nil
    }
    let red = Int((color.redComponent * 255).rounded())
    let green = Int((color.greenComponent * 255).rounded())
    let blue = Int((color.blueComponent * 255).rounded())
    let alpha = Int((color.alphaComponent * 255).rounded())
    if alpha < 255 {
      return String(format: "#%02X%02X%02X%02X", red, green, blue, alpha)
    }
    return String(format: "#%02X%02X%02X", red, green, blue)
  }

  convenience init?(hexString: String) {
    let digits = hexString.hasPrefix("#") ? String(hexString.dropFirst()) : hexString
    guard digits.count == 6 || digits.count == 8, let value = UInt64(digits, radix: 16) else {
      return nil
    }
    let rgb = digits.count == 8 ? value >> 8 : value
    let alpha = digits.count == 8 ? CGFloat(value & 0xFF) / 255 : 1
    self.init(srgbRed: CGFloat((rgb >> 16) & 0xFF) / 255, green: CGFloat((rgb >> 8) & 0xFF) / 255, blue: CGFloat(rgb & 0xFF) / 255, alpha: alpha)
  }
}
