//
//  SidebarCellAppearance.swift
//  NetNewsWire
//
//  Created by Brent Simmons on 11/24/17.
//  Copyright © 2017 Ranchero Software. All rights reserved.
//

import AppKit

struct SidebarCellAppearance: Equatable {

	let imageSize: CGSize
	let imageMarginRight: CGFloat = 4.0
	let unreadCountMarginLeft: CGFloat = 10.0
	let textFieldFontSize: CGFloat
	let textFieldFont: NSFont

	init(rowSizeStyle: NSTableView.RowSizeStyle) {
    let defaultFontSize: CGFloat
		switch rowSizeStyle {
		case .small:
			imageSize = CGSize(width: 16, height: 16)
			defaultFontSize = 11
		case .large:
			imageSize = CGSize(width: 22, height: 22)
			defaultFontSize = 15
		default:
			imageSize = CGSize(width: 19, height: 19)
			defaultFontSize = 13
		}

    let customPointSize = AppDefaults.sidebarFontPointSize
    textFieldFontSize = customPointSize > 0 ? customPointSize : defaultFontSize
    textFieldFont = AppDefaults.font(familyName: AppDefaults.sidebarFontFamily, fontName: AppDefaults.sidebarFontName, size: textFieldFontSize)
	}

  /// Only meaningful when the user chose a font size; otherwise the system row size style decides.
  var customRowHeight: CGFloat? {
    guard AppDefaults.sidebarFontPointSize > 0 else {
      return nil
    }
    return ceil(textFieldFontSize * 1.8)
  }
}
