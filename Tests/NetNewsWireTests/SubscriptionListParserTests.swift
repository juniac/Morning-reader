//
//  SubscriptionListParserTests.swift
//  NetNewsWireTests
//
//  Created by Jeong-Un Kim on 10/29/26.
//

import Testing
import Foundation
@testable import NetNewsWire

@MainActor struct SubscriptionListParserTests {

  @Test func readsOPMLWithFolderNames() throws {
    let opml = """
    <?xml version="1.0" encoding="UTF-8"?>
    <opml version="2.0"><body>
    <outline text="Blogs"><outline type="rss" text="One" xmlUrl="https://example.com/one.xml"/></outline>
    <outline type="rss" text="Two" xmlUrl="https://example.com/two.xml"/>
    </body></opml>
    """
    let feeds = try parse(opml, fileExtension: "opml")

    #expect(feeds.map(\.feedSpecifier.feedURL) == ["https://example.com/one.xml", "https://example.com/two.xml"])
    #expect(feeds.map(\.folderName) == ["Blogs", nil])
  }

  @Test func readsJSONObjectsAndBareURLs() throws {
    let json = """
    {"subscriptions": [{"title": "One", "feed_url": "https://example.com/one.xml", "site_url": "https://example.com/"}],
     "more": ["https://example.com/two.xml", "not a url"]}
    """
    let feeds = try parse(json, fileExtension: "json")

    #expect(Set(feeds.map(\.feedSpecifier.feedURL)) == ["https://example.com/one.xml", "https://example.com/two.xml"])
    let one = try #require(feeds.first { $0.feedSpecifier.feedURL == "https://example.com/one.xml" })
    #expect(one.feedSpecifier.title == "One")
    #expect(one.feedSpecifier.homePageURL == "https://example.com/")
  }

  @Test func readsHTMLBookmarks() throws {
    let html = """
    <!DOCTYPE NETSCAPE-Bookmark-file-1><DL>
    <DT><A HREF="https://example.com/one.xml">One <b>Bold</b></A>
    <DT><A HREF="javascript:void(0)">Nope</A>
    </DL>
    """
    let feeds = try parse(html, fileExtension: "html")

    #expect(feeds.count == 1)
    #expect(feeds.first?.feedSpecifier.title == "One Bold")
  }

  @Test func readsPlainTextLinesAndDropsDuplicates() throws {
    let text = """
    https://example.com/one.xml One Feed
    # a comment without a URL
    https://example.com/one.xml
    Two https://example.com/two.xml
    """
    let feeds = try parse(text, fileExtension: "txt")

    #expect(feeds.map(\.feedSpecifier.feedURL) == ["https://example.com/one.xml", "https://example.com/two.xml"])
    #expect(feeds.map(\.feedSpecifier.title) == ["One Feed", "Two"])
  }

  @Test func rejectsFilesWithoutFeeds() throws {
    #expect(throws: SubscriptionListParserError.self) {
      try parse("just some words", fileExtension: "txt")
    }
  }

  // MARK: - Helpers

  private func parse(_ contents: String, fileExtension: String) throws -> [ImportedFeed] {
    let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("SubscriptionListParserTests-\(UUID().uuidString).\(fileExtension)")
    try contents.write(to: fileURL, atomically: true, encoding: .utf8)
    defer {
      try? FileManager.default.removeItem(at: fileURL)
    }
    return try SubscriptionListParser.parse(fileURL: fileURL)
  }
}
