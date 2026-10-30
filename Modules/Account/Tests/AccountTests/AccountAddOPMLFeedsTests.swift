//
//  AccountAddOPMLFeedsTests.swift
//  AccountTests
//
//  Created by Jeong-Un Kim on 10/29/26.
//

import Testing
import RSParser
@testable import Account

@MainActor struct AccountAddOPMLFeedsTests {

  private let accountManager = TestAccountManager()

  @Test func addsChosenFeedsToTheFolderAndSkipsExistingOnes() async throws {
    let account = accountManager.createAccount(type: .onMyMac)
    defer {
      accountManager.deleteAccount(account)
    }

    // Only "Already Here" is subscribed, at the account root, before the import.
    let alreadyHereItem = try #require(try opmlItems().first)
    account.loadOPMLItems([alreadyHereItem], isManualImport: true)
    let existingFeed = try #require(account.existingFeed(withURL: "https://example.com/already-here.xml"))

    let folder = try #require(account.ensureFolder(with: "Imported"))
    let chosenSpecifiers = try opmlItems().compactMap(\.feedSpecifier).filter { $0.feedURL != "https://example.com/not-chosen.xml" }

    try await account.addOPMLFeeds(chosenSpecifiers, to: folder)

    let folderURLs = Set(folder.topLevelFeeds.map(\.url))
    #expect(folderURLs == ["https://example.com/new-one.xml"])
    #expect(account.existingContainers(withFeed: existingFeed).count == 1, "An already-subscribed feed is skipped, not duplicated into the folder.")
    #expect(account.existingFeed(withURL: "https://example.com/not-chosen.xml") == nil)

    let newFeed = try #require(account.existingFeed(withURL: "https://example.com/new-one.xml"))
    #expect(newFeed.editedName == "New One", "A title from a user-chosen file is the user's name for the feed.")
  }

  // MARK: - Helpers

  private func opmlItems() throws -> [OPMLItem] {
    let opml = """
    <?xml version="1.0" encoding="UTF-8"?>
    <opml version="1.1">
    <body>
    <outline text="Already Here" title="Already Here" type="rss" xmlUrl="https://example.com/already-here.xml"/>
    <outline text="New One" title="New One" type="rss" xmlUrl="https://example.com/new-one.xml"/>
    <outline text="Not Chosen" title="Not Chosen" type="rss" xmlUrl="https://example.com/not-chosen.xml"/>
    </body>
    </opml>
    """
    let data = try #require(opml.data(using: .utf8))
    let parserData = ParserData(url: "https://example.com/subscriptions.opml", data: data)
    let document = try OPMLParser.parseOPML(with: parserData)

    return try #require(document.children)
  }
}
