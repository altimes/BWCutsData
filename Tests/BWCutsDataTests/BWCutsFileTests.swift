//
//  BWCutsFileTests.swift
//  BWCutsData
//
//  Created by Alan Franklin on 5/6/2026.
//

import Foundation
import Testing
@testable import BWCore
@testable import BWCutsData

struct TestCutsFile {

    @Test func testContainsMark() async throws {
      // create structure equivalent to empty file
      let cutsFile = CutsFile(data: Data())
      let inEntry = CutEntry(cutPts: PtsType(0), mark: .IN)
      let outEntry = CutEntry(cutPts: PtsType(1000), mark: .OUT)
      let outEntry2 = CutEntry(cutPts: PtsType(1500), mark: .OUT)
      let bookMarkEntry = CutEntry(cutPts: PtsType(2000), mark: .BOOKMARK)
      let lastplayEntry = CutEntry(cutPts: PtsType(3000), mark: .LASTPLAY)
      #expect(cutsFile.isEmpty)
      #expect(cutsFile.isCuttable == false)
      #expect(cutsFile.addEntry(inEntry))
      #expect(!cutsFile.isEmpty)
      #expect(cutsFile.containsINorOUT)
      #expect(cutsFile.addEntry(outEntry))
      #expect(cutsFile.containsINorOUT)
      #expect(!cutsFile.contains([.BOOKMARK]))
      #expect(cutsFile.isCuttable)
      #expect(cutsFile.removeEntry(inEntry))
      #expect(cutsFile.containsINorOUT)
      #expect(cutsFile.isCuttable)
      #expect(cutsFile.addEntry(outEntry2))
      #expect(!cutsFile.isCuttable)
      #expect(cutsFile.addEntry(bookMarkEntry))
      #expect(cutsFile.contains([.BOOKMARK]))
      #expect(cutsFile.removeEntry(outEntry))
      #expect(cutsFile.removeEntry(outEntry2))
      #expect(!cutsFile.containsINorOUT)
      #expect(cutsFile.addEntry(lastplayEntry))
      #expect(cutsFile.contains([.LASTPLAY]))
      #expect(cutsFile.contains([.LASTPLAY,.BOOKMARK]))
    }

}
