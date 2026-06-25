//
//  BWCutCreationUtilitesTests.swift
//  BWCutsData
//
//  Created by Alan Franklin on 20/6/2026.
//

import Testing
@testable import BWCutsData
@testable import BWCore

struct Test {
  
  @Test func testFixedSpacing() async throws {
    // Create and empty CutsData structure
    let cutsData = CutsFile()
    
    let start = CutEntry(cutPts: PtsType.zero, mark: .IN)
    let end = CutEntry(cutPts: PtsType.eightHours, mark: .OUT)
    #expect( cutsData.addEntry(start))
    #expect( cutsData.addEntry(end))
    
    let oneHour = PtsType(UInt64(UInt64(TimeConstants.PTS_TIMESCALE) * UInt64(3_600)))
    cutsData.addFixedIntervalBookmarks(interval: oneHour, firstInCutPts: PtsType.zero, lastOutCutPts: PtsType.eightHours)
    cutsData.printCutsData()
    #expect(cutsData.bookMarks.count == 8)  // note that out and the last bookmark have same value ie: in+out+8 bookmarks
    #expect(cutsData.last?.cutPts.value == PtsType.eightHours.value)
  }
  
  // Test percentage spacing and bookmark removal
  @Test func testPercentageSpacing() async throws {
    let cutsData = CutsFile()
    
    let start = CutEntry(cutPts: PtsType.zero, mark: .IN)
    let end = CutEntry(cutPts: PtsType.eightHours, mark: .OUT)
    #expect( cutsData.addEntry(start))
    #expect( cutsData.addEntry(end))
    
    // test default spacing of 10 percent
    cutsData.addPercentageBookMarks()
    #expect(cutsData.bookMarks.count == 10)
    
    // test removal of only Bookmarks
    cutsData.removeEntriesOfType(.BOOKMARK)
    #expect(cutsData.count == 2)
    
    // test adding 25 percent spacing
    cutsData.addPercentageBookMarks(3)
    #expect(cutsData.count == 6)
    
  }
  
  @Test func testCountAndInterval() async throws {
    let cutsData = CutsFile()
    
    let start = CutEntry(cutPts: PtsType.zero, mark: .IN)
    let end = CutEntry(cutPts: PtsType.eightHours, mark: .OUT)
    #expect( cutsData.addEntry(start))
    #expect( cutsData.addEntry(end))
    
    let oneHourAsDouble = Double(TimeConstants.PTS_TIMESCALE * 3600)
    let fiveHourPts = PtsType(oneHourAsDouble * 5.0 )
    let threeHourPts = PtsType(oneHourAsDouble * 3.0)
    //    let fourHourPts = PtsType(oneHourAsDouble * 4.0)
    let oneHourPts: PtsType = PtsType(oneHourAsDouble)
    let balance = cutsData.addMarks(fromPos: cutsData.first!.cutPts, upToPos: fiveHourPts, spacing: oneHourPts)
    print("Balance: \(balance.hhMMss)")
    
    cutsData.printCutsData()
    #expect(balance == threeHourPts)
    #expect(cutsData.count == 7)
  }
  
  @Test func testCuttable() async throws {
    let oneHourAsDouble = Double(TimeConstants.PTS_TIMESCALE * 3600)
    let fourHourPts = PtsType(oneHourAsDouble * 4.0)
    let start = CutEntry(cutPts: PtsType.zero, mark: .IN)
    let midIn = CutEntry(cutPts: fourHourPts, mark: .IN)
    let midOut = CutEntry(cutPts: fourHourPts, mark: .OUT)
    let end = CutEntry(cutPts: PtsType.eightHours, mark: .OUT)
    
    let cutsData = CutsFile()
    // test empty
    #expect(cutsData.isCuttable == false)
    // test in only
    #expect(cutsData.addEntry(start))
    #expect(cutsData.isCuttable == true)
    // test in .. out
    #expect(cutsData.addEntry(end))
    #expect(cutsData.isCuttable == true)
    // test in .. in .. out
    #expect(cutsData.addEntry(midIn))
    #expect(cutsData.isCuttable == false)
    // test in .. out .. out
    #expect(cutsData.removeEntry(midIn))
    #expect(cutsData.addEntry(midOut))
    #expect(cutsData.isCuttable == false)
  }
}
