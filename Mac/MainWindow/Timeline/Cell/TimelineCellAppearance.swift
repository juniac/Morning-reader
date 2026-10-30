//
//  TimelineCellAppearance.swift
//  NetNewsWire
//
//  Created by Brent Simmons on 2/6/16.
//  Copyright © 2016 Ranchero Software, LLC. All rights reserved.
//

import AppKit

struct TimelineCellAppearance: Equatable {

	let showIcon: Bool

	let cellPadding: NSEdgeInsets

	let feedNameFont: NSFont

	let dateFont: NSFont
	let dateMarginLeft: CGFloat = 8.0

	let titleFont: NSFont
	let titleBottomMargin: CGFloat = 1.0
	let titleNumberOfLines = 3

	let textFont: NSFont

	let textOnlyFont: NSFont

	let unreadCircleDimension: CGFloat = 8.0
	let unreadCircleMarginRight: CGFloat = 8.0

	let starDimension: CGFloat = 13.0

	let drawsGrid = false

	let iconSize: NSSize
	let iconMarginLeft: CGFloat = 8.0
	let iconMarginRight: CGFloat = 8.0
	let iconAdjustmentTop: CGFloat = 4.0
	let iconCornerRadius: CGFloat
  let iconDrawsBackground: Bool

	let boxLeftMargin: CGFloat

	init(showIcon: Bool, fontSize: FontSize) {

		let actualFontSize = AppDefaults.actualFontSize(for: fontSize)
    let customTitleSize = AppDefaults.timelineTitleFontPointSize
    let customSummarySize = AppDefaults.timelineSummaryFontPointSize
    let titleSize = customTitleSize > 0 ? customTitleSize : actualFontSize
    let summarySize = customSummarySize > 0 ? customSummarySize : actualFontSize
    let smallItemFontSize = floor(titleSize * 0.90)
    let familyName = AppDefaults.timelineFontFamily

    self.feedNameFont = AppDefaults.font(familyName: familyName, size: smallItemFontSize, weight: .bold)
    self.dateFont = AppDefaults.font(familyName: familyName, size: smallItemFontSize, weight: .bold)
    // The picked face goes on the title; Bold Title then adds the bold trait on top of it.
    let titleWeight: NSFont.Weight = AppDefaults.timelineTitleIsBold ? .semibold : .regular
    var titleFont = AppDefaults.font(familyName: familyName, fontName: AppDefaults.timelineFontName, size: titleSize, weight: titleWeight)
    if AppDefaults.timelineFontName != nil, AppDefaults.timelineTitleIsBold {
      titleFont = NSFontManager.shared.convert(titleFont, toHaveTrait: .boldFontMask)
    }
    self.titleFont = titleFont
    let summaryWeight: NSFont.Weight = AppDefaults.timelineSummaryIsBold ? .semibold : .regular
    self.textFont = AppDefaults.font(familyName: familyName, size: summarySize, weight: summaryWeight)
    self.textOnlyFont = AppDefaults.font(familyName: familyName, size: summarySize, weight: summaryWeight)

		self.showIcon = showIcon

    let iconDimension = AppDefaults.timelineIconDimension
    let iconShape = AppDefaults.timelineIconShape
    self.iconSize = NSSize(width: iconDimension, height: iconDimension)
    self.iconCornerRadius = iconShape.cornerRadius(forDimension: iconDimension)
    self.iconDrawsBackground = iconShape.drawsBackground

		cellPadding = NSEdgeInsets(top: 8.0, left: 4.0, bottom: 10.0, right: 4.0)

		let margin = self.cellPadding.left + self.unreadCircleDimension + self.unreadCircleMarginRight
		self.boxLeftMargin = margin
	}
}

extension NSEdgeInsets: @retroactive Equatable {

	public static func ==(lhs: NSEdgeInsets, rhs: NSEdgeInsets) -> Bool {
		return lhs.left == rhs.left && lhs.top == rhs.top && lhs.right == rhs.right && lhs.bottom == rhs.bottom
	}
}
