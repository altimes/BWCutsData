//
//  CutsData+Utitlies.swift
//  BWCutsData
//
//  Created by Alan Franklin on 21/5/2026.
//

// Utility functions extract to reduce CutsData file size and
// leave the CutsFile file to represent basic creation
// management

import Foundation
import BWCore

extension CutsFile {

  
  // MARK: Bookmark Creation Functions
  
  
  /// Add bookmarks to the array at a fixed time interval.
  ///
  /// Early simplistic implementation to caculate PTS value from first
  /// PTS value.  Later may interogate .ap file for nearest PTS value.
  /// Honour out/in marks, the interval is a program interval (as defined by OUT/IN)
  /// markers, not simple recording duration
  ///
  /// Note that this deliberately avoids a begin boundary bookmark
  /// Cutting appears to occur on GOP boundaries and can end up with negative PTS
  /// bookmarks.
  
  /// - parameter interval: interval between bookmarks in seconds
  /// - parameter firstInCutPts: pts value of the start position
  /// - parameter lastOutCutPts: pts value of the end position
  
  public func addFixedIntervalBookmarks (interval: PtsType, firstInCutPts: PtsType, lastOutCutPts: PtsType, metaDuration: Double? = 0.0, apRuntimePTS: PtsType? = PtsType(0))
  {
    var lastPts = lastOutCutPts
    
    // being careful of parameter values that will come from recording in which a
    // a PCR reset can occur at any time.  This sets the PTS back to zero, thus we
    // have to be able to smoothly handle the situation where the 'lastOutCutPts' is a
    // smaller value than 'firstInCutPts'  -  nuts we know, but that is broadcasting for you..
    if (firstInCutPts < lastOutCutPts)  // important for UIntXX values
    {
      // get duration from meta and compare to first / last pts range
      // editted file will result in a substantial mismatch
      if let metaDuration = metaDuration, let apRuntimePTS = apRuntimePTS{
        let ptsDuration = Double(lastOutCutPts - firstInCutPts)
        let durationDiff = abs(ptsDuration-metaDuration)
        // is the diffrence > 30 secs ?
        if metaDuration != 0 && durationDiff > 30.0*Double(TimeConstants.PTS_TIMESCALE) {
          // file has had advertisements removed, check that last matches the ap data
            lastPts = firstInCutPts + apRuntimePTS
          // FIXME: this algorithm is broken for edited file (in/outs) are missing
          // might be fixable by finding gaps and inserting temp in/out at gap boundaries
        }
      }
      
      // alogrithm is to: create a temporary table of only INs and OUTs.
      // balance IN/OUT sequence to ensure that we start IN and end OUT
      // and then process the IN/OUT pairs
      
      var inOut = inOutOnly
      
      // no marks, generate a pair
      if (inOut.count == 0 ) {
        inOut.append(CutEntry(cutPts: firstInCutPts, mark: .IN))
        inOut.append(CutEntry(cutPts: lastPts, mark: .OUT))
      }
      
      // assert inOut is NOT emptry
      
      // first mark is OUT, generate an IN at the begining
      if (inOut.first!.type == MARK_TYPE.OUT) {
        inOut.insert(CutEntry(cutPts: firstInCutPts, mark: MARK_TYPE.IN), at: 0)
      }
      
      // last mark is IN, generate an OUT at the end
      if (inOut.last!.type != MARK_TYPE.OUT) {
        inOut.append(CutEntry(cutPts: lastPts, mark: .OUT))
      }
      
      // assert inOut is now always IN/OUT, [IN/OUT], .... in the inOut array
      
      var index = 0
      var used = PtsType(0)
      while (index < inOut.count)
      {
        let nextInMark = inOut[index]
        let nextOutMark = inOut[index+1]
        let startPts = PtsType(nextInMark.cutPts-used)
        if (debug) {print ("used: \(Double(used)*TimeConstants.PTS_DURATION) in: \(nextInMark.asSeconds()), start:\(Double(startPts)*TimeConstants.PTS_DURATION), out:\(nextOutMark.asSeconds())")}
        used = addMarks(fromPos: startPts, upToPos: nextOutMark.cutPts, spacing: interval)
        index += 2
      }
      modified = true
    }
  }
  
  /// Add bookmarks to the array at a fixed time interval.
  /// Early simplistic implementation to caculate PTS value from first
  /// PTS value.  Later may interogate .ap file for nearest PTS value.
  /// Uses preference value for time interval
  /// Note that this deliberately avoids a begin boundary bookmark
  /// Cutting occurs on GOP boundaries and can end up with negative
  /// bookmarks.
  
  /// - parameter interval: interval between bookmarks in seconds
  
  public func addFixedTimeBookmarks (interval: Int)
  {
    let intervalInSeconds = interval
    let (first, last) = startEnd()
    let ptsIncrement = PtsType( intervalInSeconds*Int(TimeConstants.PTS_TIMESCALE))
    addFixedIntervalBookmarks(interval: ptsIncrement, firstInCutPts: first, lastOutCutPts: last ?? PtsType.eightHours)
  }

  /// Add bookmarks to the collection at the spacing from the given start position
  /// up to the given end position. calculates and returns the last "used" part of the spacing
  /// to enable the next bookmark create to compensate for unused portion and ensure even
  /// bookmarks in relation to program content
  /// - parameter fromPos: start value
  /// - parameter upToPos: value not to create bookmarks beyond
  /// - parameter spacing: spacing of bookmarks
  /// - returns : remainder of unused spacing
  public func addMarks(fromPos: PtsType, upToPos: PtsType, spacing: PtsType) -> PtsType
  {
    var initialBookmarkPosition: PtsType
    if (debug) { print("received start at: \(Double(fromPos)*TimeConstants.PTS_DURATION)") }
    initialBookmarkPosition = fromPos + spacing
    while initialBookmarkPosition <= upToPos {
      if (debug) { print("Creating entry at \(Double(initialBookmarkPosition)*TimeConstants.PTS_DURATION) for spacing of \(Double(spacing)*TimeConstants.PTS_DURATION)") }
      _ = addEntry(CutEntry(cutPts: initialBookmarkPosition, mark: .BOOKMARK))
      initialBookmarkPosition += spacing
    }
    // FIXME: fails here when editing an already edited file. - problem with the gaps
    let unused = self.last!.cutPts - upToPos
    if (debug) { print("returning remainder of \(Double(unused)*TimeConstants.PTS_DURATION)") }
    return unused
  }
  
  /// Add fixed NUMBER of bookmarks
  /// Note that this deliberately avoids adding bookmarks
  /// on the begin and end boundaries.
  /// Due to the observation that when cutting is done after bookmarks
  /// are inserted and that cutting seems to occur
  /// on GOP boundaries, then it can end up with negative
  /// bookmarks that cause all sorts of grief to avplayers
  /// Default value gives bookmarks at 10 % spacing
  
  /// - parameter numberOfMarks: how many bookmarks to interpolate between begin and end positions
  
  public func addPercentageBookMarks(_ numberOfMarks: Int = 9)
  {
    let (first, last) = startEnd()
    // get duration
    let programLength =  playable(startPTS: first, endPTS: last ?? PtsType.eightHours)
    let ptsOffset = programLength / PtsType(numberOfMarks+1)
    addFixedIntervalBookmarks(interval: ptsOffset, firstInCutPts: first, lastOutCutPts: last ?? PtsType.eightHours)
  }
  
  // MARK: Query Functions
  
  /// Check if array has a matching (==) entry
  /// Wrapper function to hide implementation detail
  /// - parameter cutEntry: entry to search for
  public func contains(_ entry: CutEntry) -> Bool
  {
    return cutsArray.contains(entry)
  }

  /// Get a formatted string of the entry if that entry is of any type that is in the set of cut types given
  /// - parameter cutEntry: entry to be formatted if it matches the condition
  /// - parameter markSet: Set of required mark types
  public func cutDataMarkOfTypeAsString(_ cutEntry: CutEntry, markSet : Set<MARK_TYPE>) -> String?
  {
    var result : String? = nil
    if (markSet.contains(cutEntry.type))
    {
      result =  cutEntry.asString()
    }
    return result
  }

  /// Returns the result of checking the cuts list for consistency.
  /// That is, ensure OUTs and INs are always alternating
  /// - returns: changed state
  public var isCuttable : Bool {
    get {
      let validation = self.validateInOut()
      lastValidationMessage = validation.errorMessage
      return (self.inOutOnly.count > 0 && validation.result)
    }
  }
  
  // MARK: Debug utilities
  
  /// Utility debug to verify order and contents of collection
  public func printCutsData()
  {
    var lineNumber = 0
    for entry in cutsArray {
      print("\(lineNumber) = " + entry.asStringDecimal())
      lineNumber += 1
    }
  }
  
  /// Utility debug to verify order and contents of collection
  public func printCutsDataAsHex()
  {
    var lineNumber = 0
    for entry in cutsArray {
      print("\(lineNumber) = " + entry.asHex())
      lineNumber += 1
    }
  }
  
  /// Utility debug to verify order and contents of collection.
  ///  Print to console  in/out list from array
  
  public func printInOut()
  {
    let inOutSet = Set([MARK_TYPE.OUT,MARK_TYPE.IN])
    printSetOfType(inOutSet)
  }
  
  /// Utility debug to verify order and contents of collection.
  /// Print to console bookmark list from array
  
  public func printBookmark()
  {
    let  bookMarkSet = Set([MARK_TYPE.BOOKMARK])
    printSetOfType(bookMarkSet)
  }
  
  /// Utility debug to verify order and contents of collection
  ///  Print to console  items that match the set member type
  /// - parameter markSet: Set of required mark types
  public func printSetOfType(_ markSet : Set<MARK_TYPE>) {
    var lineNumber = 0
    for entry in cutsArray {
      if let item = cutDataMarkOfTypeAsString(entry, markSet: markSet)
      {
        print("\(lineNumber) \(item)")
      }
      lineNumber += 1
    }
  }
}
