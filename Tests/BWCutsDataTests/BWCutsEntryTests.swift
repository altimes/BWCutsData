//
//  Test.swift
//  BWCutsData
//
//  Created by Alan Franklin on 3/6/2026.
//

import Testing
@testable import BWCutsData
@testable import BWCore

struct TestCutsEntry {

  @Test func testEqual() async throws {
    let entry1 = CutEntry(cutPts: PtsType(500), mark: .IN)
    let entry2 = CutEntry(cutPts: PtsType(500), mark: .IN)
    let entry3 = CutEntry(cutPts: PtsType(200), mark: .IN)
    #expect(entry1 == entry2)
    #expect(entry1 != entry3)
  }
  @Test func testComparable() async throws {
      // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    let entry1 = CutEntry(cutPts: PtsType(500), mark: .IN)
    let entry2 = CutEntry(cutPts: PtsType(400), mark: .IN)
    let entry3 = CutEntry(cutPts: PtsType(200), mark: .IN)
    #expect(entry1 > entry2)
    #expect(entry3 < entry2)
  }
  
  @Test func testMarkCreation() async throws {
    let fileValue = MARK_TYPE.BOOKMARK.rawValue.bigEndian
    let mark = UInt32(fileValue)
    let pts = PtsType(90_000_000)
    let entry = CutEntry(cutPts: pts, type: mark.bigEndian)
    #expect(entry.cutPts.asSeconds == 1000.0)
    #expect(entry.type == .BOOKMARK)
    
    let markValue = MARK_TYPE.OUT
    let entry2 = CutEntry(cutPts: pts, mark: markValue)
    #expect(entry2.type.rawValue == MARK_TYPE.OUT.rawValue)
  }
  
  @Test func testDebug() async throws {
    let fileValue = MARK_TYPE.BOOKMARK.rawValue.bigEndian
    let mark = UInt32(fileValue)
    let pts = PtsType(90_000_000)
    let entry = CutEntry(cutPts: pts, type: mark.bigEndian)
    #expect(entry.asHex() == "00000000055d4a80:00000002")
    let duration = entry.cutPts.asSeconds
    let display = CutEntry.hhMMssFromSeconds(duration)
    #expect(display == "16:40")
    let display2 = CutEntry.hhMMssFromSeconds(duration, resolution: 1.0)
    #expect(display2 == "16:40.00")
  }

}
