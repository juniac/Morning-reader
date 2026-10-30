//
//  SubscriptionListParser.swift
//  NetNewsWire
//
//  Created by Jeong-Un Kim on 10/29/26.
//  Copyright © 2026 Ranchero Software. All rights reserved.
//

import Foundation
import RSParser

struct ImportedFeed {
  let feedSpecifier: OPMLFeedSpecifier
  let folderName: String?
}

enum SubscriptionListParserError: LocalizedError {
  case unsupportedFormat(fileName: String)
  case noFeedsFound(fileName: String)

  var errorDescription: String? {
    switch self {
    case .unsupportedFormat(let fileName):
      let formatString = NSLocalizedString("“%@” is not a subscription list Morning can read.", comment: "Import subscriptions error")
      return String(format: formatString, fileName)
    case .noFeedsFound(let fileName):
      let formatString = NSLocalizedString("“%@” does not contain any feeds.", comment: "Import subscriptions error")
      return String(format: formatString, fileName)
    }
  }

  var recoverySuggestion: String? {
    NSLocalizedString("Supported: OPML, a NetNewsWire 3 Subscriptions.plist, JSON or plain-text lists of feed URLs, and HTML bookmarks.", comment: "Import subscriptions error")
  }
}

/// Reads the subscription lists other readers export: OPML (what nearly every reader exports), a NetNewsWire 3
/// Subscriptions.plist, JSON or plain-text URL lists, and HTML bookmark files. The format is sniffed from the content,
/// not the extension, because exports are often saved as .xml or .txt.
@MainActor enum SubscriptionListParser {

  static func parse(fileURL: URL) throws -> [ImportedFeed] {
    let data = try Data(contentsOf: fileURL)
    let fileName = fileURL.lastPathComponent
    let text = String(decoding: data, as: UTF8.self)

    let feeds: [ImportedFeed]
    if text.localizedCaseInsensitiveContains("<opml") || text.localizedCaseInsensitiveContains("<outline") {
      feeds = try opmlFeeds(data: data, url: fileURL.absoluteString)
    } else if let document = NNW3Document(subscriptionsPlistURL: fileURL) {
      let opml = document.OPMLString(indentLevel: 0, allowCustomAttributes: false)
      feeds = try opmlFeeds(data: Data(opml.utf8), url: fileURL.absoluteString)
    } else if let json = try? JSONSerialization.jsonObject(with: data) {
      feeds = jsonFeeds(in: json)
    } else if text.localizedCaseInsensitiveContains("<a ") && text.localizedCaseInsensitiveContains("href=") {
      feeds = htmlFeeds(in: text)
    } else if !text.isEmpty, !data.contains(0) {
      feeds = plainTextFeeds(in: text)
    } else {
      throw SubscriptionListParserError.unsupportedFormat(fileName: fileName)
    }

    let uniqueFeeds = removingDuplicateURLs(feeds)
    guard !uniqueFeeds.isEmpty else {
      throw SubscriptionListParserError.noFeedsFound(fileName: fileName)
    }
    return uniqueFeeds
  }
}

// MARK: - Private

private extension SubscriptionListParser {

  static func opmlFeeds(data: Data, url: String) throws -> [ImportedFeed] {
    let document = try OPMLParser.parseOPML(with: ParserData(url: url, data: data))
    return flattenedFeeds(in: document.children ?? [], folderName: nil)
  }

  /// Feeds nested in OPML folders are listed flat; the folder name is kept only for display.
  static func flattenedFeeds(in items: [OPMLItem], folderName: String?) -> [ImportedFeed] {
    var feeds = [ImportedFeed]()
    for item in items {
      if let feedSpecifier = item.feedSpecifier {
        feeds.append(ImportedFeed(feedSpecifier: feedSpecifier, folderName: folderName))
      } else if let children = item.children {
        feeds += flattenedFeeds(in: children, folderName: item.titleFromAttributes ?? folderName)
      }
    }
    return feeds
  }

  // ponytail: there is no standard JSON subscription format, so this walks the whole document and takes
  // any object with a feed-URL-looking key (Feedbin, Inoreader, and hand-written lists all fit) and any bare URL string.
  static let jsonFeedURLKeys = ["xmlUrl", "xmlurl", "xml_url", "feedUrl", "feedURL", "feed_url", "feed", "rss", "url"]
  static let jsonTitleKeys = ["title", "text", "name"]
  static let jsonHomePageKeys = ["htmlUrl", "htmlurl", "html_url", "siteUrl", "site_url", "website", "homePageURL"]

  static func jsonFeeds(in json: Any, folderName: String? = nil) -> [ImportedFeed] {
    switch json {
    case let array as [Any]:
      return array.flatMap { jsonFeeds(in: $0, folderName: folderName) }
    case let string as String:
      guard let feedURL = feedURLString(string) else {
        return []
      }
      return [ImportedFeed(feedSpecifier: OPMLFeedSpecifier(title: nil, feedDescription: nil, homePageURL: nil, feedURL: feedURL), folderName: folderName)]
    case let dictionary as [String: Any]:
      let feedURL = jsonFeedURLKeys.lazy.compactMap { dictionary[$0] as? String }.compactMap(feedURLString).first
      let title = jsonTitleKeys.lazy.compactMap { dictionary[$0] as? String }.first
      if let feedURL {
        let homePageURL = jsonHomePageKeys.lazy.compactMap { dictionary[$0] as? String }.first
        return [ImportedFeed(feedSpecifier: OPMLFeedSpecifier(title: title, feedDescription: nil, homePageURL: homePageURL, feedURL: feedURL), folderName: folderName)]
      }
      // A container object: its title names the group for the feeds inside it.
      return dictionary.values.flatMap { jsonFeeds(in: $0, folderName: title ?? folderName) }
    default:
      return []
    }
  }

  static func htmlFeeds(in html: String) -> [ImportedFeed] {
    guard let regex = try? NSRegularExpression(pattern: #"<a\s[^>]*href\s*=\s*["']([^"']+)["'][^>]*>(.*?)</a>"#, options: [.caseInsensitive, .dotMatchesLineSeparators]) else {
      return []
    }
    let range = NSRange(html.startIndex..., in: html)
    return regex.matches(in: html, range: range).compactMap { match in
      guard let urlRange = Range(match.range(at: 1), in: html), let feedURL = feedURLString(String(html[urlRange])) else {
        return nil
      }
      let title = Range(match.range(at: 2), in: html).flatMap { strippingTags(String(html[$0])) }
      return ImportedFeed(feedSpecifier: OPMLFeedSpecifier(title: title, feedDescription: nil, homePageURL: nil, feedURL: feedURL), folderName: nil)
    }
  }

  /// One feed per line: the URL, optionally followed by a title.
  static func plainTextFeeds(in text: String) -> [ImportedFeed] {
    text.components(separatedBy: .newlines).compactMap { line in
      let words = line.split(whereSeparator: \.isWhitespace).map(String.init)
      guard let urlIndex = words.firstIndex(where: { feedURLString($0) != nil }), let feedURL = feedURLString(words[urlIndex]) else {
        return nil
      }
      let titleWords = words.enumerated().filter { $0.offset != urlIndex }.map(\.element)
      let title = titleWords.isEmpty ? nil : titleWords.joined(separator: " ")
      return ImportedFeed(feedSpecifier: OPMLFeedSpecifier(title: title, feedDescription: nil, homePageURL: nil, feedURL: feedURL), folderName: nil)
    }
  }

  static func feedURLString(_ candidate: String) -> String? {
    let trimmed = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let url = URL(string: trimmed), let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" || scheme == "feed", url.host != nil else {
      return nil
    }
    return trimmed
  }

  static func strippingTags(_ html: String) -> String? {
    let text = html.replacingOccurrences(of: #"<[^>]+>"#, with: "", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)
    return text.isEmpty ? nil : text
  }

  static func removingDuplicateURLs(_ feeds: [ImportedFeed]) -> [ImportedFeed] {
    var seenURLs = Set<String>()
    return feeds.filter { seenURLs.insert($0.feedSpecifier.feedURL).inserted }
  }
}
