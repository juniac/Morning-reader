//
//  UserKeyboardShortcutsTests.swift
//  NetNewsWireTests
//
//  Created by Jeong-Un Kim on 10/29/26.
//

import Testing
import AppKit
import RSCore
@preconcurrency import KeyboardShortcuts
@testable import NetNewsWire

@MainActor struct UserKeyboardShortcutsTests {

  @Test func bareLettersUseTheLowercaseCharacter() throws {
    let dictionary = try #require(UserKeyboardShortcuts.shortcutDictionary(for: KeyboardShortcuts.Shortcut(.r), actionString: "refreshAll:"))
    #expect(dictionary["key"] as? String == "r")
    #expect(dictionary["shiftModifier"] as? Bool == false)
    #expect(KeyboardShortcut(dictionary: dictionary)?.actionString == "refreshAll:")
  }

  @Test func shiftedLettersUseTheUppercaseCharacterLikeTheEvent() throws {
    let dictionary = try #require(UserKeyboardShortcuts.shortcutDictionary(for: KeyboardShortcuts.Shortcut(.b, modifiers: [.shift, .command]), actionString: "openInBrowser:"))
    #expect(dictionary["key"] as? String == "B")
    #expect(dictionary["shiftModifier"] as? Bool == true)
    #expect(dictionary["commandModifier"] as? Bool == true)
  }

  @Test func specialKeysUseThePlistNames() throws {
    let space = try #require(UserKeyboardShortcuts.shortcutDictionary(for: KeyboardShortcuts.Shortcut(.space), actionString: "x:"))
    let upArrow = try #require(UserKeyboardShortcuts.shortcutDictionary(for: KeyboardShortcuts.Shortcut(.upArrow), actionString: "x:"))
    #expect(space["key"] as? String == "[space]")
    #expect(upArrow["key"] as? String == "[uparrow]")
    #expect(KeyboardShortcut(dictionary: upArrow) != nil)
  }
}
