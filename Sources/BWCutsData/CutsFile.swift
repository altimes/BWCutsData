//
//  CutsFile.swift
//
//  Created by Alan Franklin on 31/03/2016.
//  Copyright © 2016 Alan Franklin. All rights reserved.
//
//  Models the Beyonwiz (Enigma2) .cuts file

import AVFoundation
import BWCore

/// Models the collection of cut/book/lastplay marks associated with a recording
final public class CutsFile: Copyable, MutableCollection {
  
  /// collection of cut marks, internally maintained to be in time (pts) order
  // TODO: check what happens with discontinuities with PTS values
  var cutsArray = [CutEntry]()
  {
    didSet {
      print("Changed to \(cutsArray)")
    }
  }
  
  /// Return number of elements in cuts collection
  public var count : Int
    {
    get { return cutsArray.count }
  }
  
  /// Accessor to Parent container
//  var container : Recording?
  // MARK: Utility properties
  
  /// Get the CoreMedia time of the first mark in the cuts collection.
  /// If the collection is empty then return zero time.
  var firstMarkTime : CMTime {
    get {
      var startTime: CMTime
      if let firstMark = self.first {
        startTime = CMTimeMake(value: Int64(firstMark.cutPts.value), timescale: TimeConstants.PTS_TIMESCALE)
      }
      else {
        startTime = CMTime(seconds: 0.0, preferredTimescale: 1)
      }
      return startTime
    }
  }
  
  /// Get earliest (pts time based) cut entry in the collection or nil if there is none
  public var first: CutEntry? {
    get {
      return cutsArray.first
    }
  }
  
  /// Get latest (pts time based) cut entry in collection or nil if there is none
  public var last: CutEntry? {
    get {
      return cutsArray.last
    }
  }
  
  /// Get the last OUT mark (pts time based) cut entry in collection or nil if there is none
  public var lastOutCutMark: CutEntry? {
    get {
      let OUTArray = cutsArray.filter() {$0.type == MARK_TYPE.OUT}
      return OUTArray.last
    }
  }
  
  /// Get the first IN mark (pts time based) cut entry in collection or nil if there is none
  public var firstInCutMark: CutEntry? {
    get {
      let INArray = cutsArray.filter() {$0.type == MARK_TYPE.IN}
      return INArray.first
    }
  }
  
  /// Get the first OUT mark (pts time based) cut entry in collection or nil if there is none
  public var firstOutCutMark: CutEntry? {
    get {
      let OUTArray = cutsArray.filter() {$0.type == MARK_TYPE.OUT}
      return OUTArray.first
    }
  }
  
  /// Array of only the IN and OUT cutmarks in time order
  public var inOutOnly: [CutEntry] {
    get {
      let inOut = cutsArray.filter{$0.type == MARK_TYPE.IN || $0.type == MARK_TYPE.OUT}
//      print("In/Out count = \(inOut.count)")
      return inOut
    }
  }
  
  /// Fully Bounded array of IN and OUT cutmarks in time order
  /// Ensure that complete duration is covered by fabricating any implied starter IN mark and terminal OUT mark
  public var fullInOutOnly: [CutEntry] {
    return createFullInOutTable(partialInOut: inOutOnly)
  }
  
  // TODO: to be injected
  var durationInPTSFromAccessPoints = PtsType.zero
  
  // TODO: to be intected
  var lastOutCutPTS = PtsType.zero
  
  // TODO: to be injected ?
  var metaDuration: Double?
  
  // TODO: to be injected ?
  var runtimePTS: PtsType?
  
  // TODO: to be injected ?
/// injected when/if player comes ready with video
  var videoDurationFromPlayer: Double = 0.0
  
  // TODO: to be injected ?
  var cache: Cache<String,Data>?

  // TODO: to be injected ?
  var apLastPTS: PtsType?
  
  // TODO: to be injected ?
  var apHasGaps: Bool?
  
  var runTimeFromFromPlayer: ((_ pts: PtsType) -> PtsType)?
  var bestDurationAndApDurationInSeconds: ((_ playerDuration: Double) -> (best: Double, ap: Double))?

  
  // create a table that is guaranteed marks at terminal postions
  // importantly note that ap pts are broadcast pts, cuts file pts are zero baseed
  // that is, do not mix pts ap values with cutsfile values without adjustment
  func createFullInOutTable(partialInOut: [CutEntry]) -> [CutEntry]
  {
    let firstPos = PtsType(0)
    let lastPos =  durationInPTSFromAccessPoints
    let firstCut = CutEntry(cutPts: firstPos, mark: .IN)
    let lastCut = CutEntry(cutPts: lastPos, mark: .OUT)
    print("fabed first: \(firstCut)")
    print("fabed last:  \(lastCut)")
    
    guard (partialInOut.count > 0) else {
      print("Found 0 in/out returning \(firstCut)/\(lastCut)")
      return [firstCut,lastCut] }
    
    
    var inOutTable = [CutEntry]()
    // edge cases
    // single IN mark
    // single OUT mark
    if (partialInOut.count == 1)
    {
      // Single Mark, use fabricated boundary mark
      if (partialInOut[0].type == MARK_TYPE.IN) {
        inOutTable = [partialInOut[0],lastCut]
      }
      else {
        inOutTable = [firstCut, partialInOut[0]]
      }
      return inOutTable
    }
    else {
      // now determine if we start with IN or OUT
      if (partialInOut[0].type == MARK_TYPE.IN)
      {
        inOutTable.append(CutEntry(cutPts: firstPos, mark: .OUT))
      }
      else { // lowest is OUT, so fabricate and IN at 0.0
        inOutTable.append(CutEntry(cutPts: firstPos, mark: .IN))
      }
      // now interleave IN/OUT pairs watching for inconsistent marks
      // if sequential OUTs with intervening IN, take earliest,
      // if duplicate INs without intervening OUT take latest
      var last = 0
      for index in 0 ..< partialInOut.count
      {
        if partialInOut[index].type != inOutTable[last].type
        {
          inOutTable.append(partialInOut[index])
          last += 1
        }
        else // duplication of mark type
        {
          if (partialInOut[index].type == MARK_TYPE.IN)
          {
            // use later IN
            inOutTable[last] = partialInOut[index]
          }
          else
          {
            // use earlier OUT value, ie ignor later OUT mark
            inOutTable[last] = inOutTable[last]
          }
        }
      }
    }
    // now ensure that we have a final Mark
    if (inOutTable.last!.cutPts < lastPos) {
      let finalInOutMark = CutEntry(cutPts: lastPos, mark: (inOutTable.last?.type == MARK_TYPE.OUT) ? .IN: .OUT)
      inOutTable.append(finalInOutMark)
    }
    return inOutTable
  }

  /// Array of only the bookmarks
  public var bookMarks: [CutEntry] {
    get {
      let arrayOfBookMarks = cutsArray.filter{$0.type == MARK_TYPE.BOOKMARK}
      return arrayOfBookMarks
    }
  }
 
  /// Message string from the last validation performed
  var lastValidationMessage: String = ""
  
  /// Has the list of cuts been changed
  /// - returns: changed state
  public var isModified : Bool {
     get {
      return modified
    }
  }
  
  /// internal flag if any change is made to the collection
  var modified = false
  
  var debug = false
  
  // MARK: Initializers
  
  init(runTimeFromFromPlayer: ((_ pts: PtsType)->PtsType)? = nil,
       bestDurationAndApDurationInSeconds: ((_ playerDuration:Double )->(best:Double, ap:Double))? = nil
  )
  {
    self.runTimeFromFromPlayer = runTimeFromFromPlayer
    self.bestDurationAndApDurationInSeconds = bestDurationAndApDurationInSeconds
  }
  
  convenience init(data: Data)
  {
    self.init()
    self.decodeCutsData(data)
  }
  
  required init(_ model: CutsFile) {
    cutsArray = model.cutsArray
    modified = model.modified
    debug = model.debug
    lastValidationMessage = model.lastValidationMessage
//    container = model.container
  }
  
  // supporting functions
  /// Derives and returns first and last position in a video file
  /// from the cutmarks and video information
  /// - returns : firstIN and lastOut mark points as PtsType
  func startEnd() -> (firstIN: PtsType, lastOUT: PtsType)
  {
    let firstInCutPts =  (count != 0) ? ((first!.type == MARK_TYPE.IN) ? first!.cutPts : PtsType(0)) : PtsType(0)
    let lastPTS =   ((inOutOnly.count > 0) && (inOutOnly.last!.type == MARK_TYPE.OUT)) ? inOutOnly.last!.cutPts : lastOutCutPTS
    return(firstInCutPts, lastPTS)
  }
  
  /// return the recording duration with respect to OUT / IN markers
  /// return duration from movie otherwise
  func playable(startPTS: PtsType, endPTS: PtsType) -> PtsType
  {
    var playableDurationInPts = (endPTS - startPTS)
    guard  (isCuttable) else { return playableDurationInPts }
    
    let inOut = inOutOnly
    if inOut.count != 0
    {
      var index = 0
      // prime the loop - deal with leading IN marker
      if inOut[index].type == MARK_TYPE.IN {
        let leadingOutCut = (inOut[index].cutPts - startPTS)
        playableDurationInPts -= leadingOutCut
        index += 1
      }
      
      // loop invar inOut[index] is an OUT marker && index+1 is valid
      while (index < inOut.count-1)
      {
        let outInDurationInPts = (inOut[index+1].cutPts - inOut[index].cutPts)
        playableDurationInPts -= outInDurationInPts
        index += 2
      }
      
      // finalize the loop  - deal with trailing OUT marker
      if (inOut.last!.type == MARK_TYPE.OUT) {
        let trailingOutCut = (endPTS - inOut.last!.cutPts)
        playableDurationInPts -= trailingOutCut
      }
    }
    return playableDurationInPts
  }
  
  /// Find the earliest position in the video.  This should be;
  /// the first IN mark not preceed by an out Mark,
  /// failing that, if there are <= 3 bookmarks,
  /// use the first bookmark - most likely an unedited file.
  /// Otherwise use then use the initial file position
  /// which may have to be fabricated if it does not exist.
  
  func firstVideoPosition() -> CutEntry
  {
    if let firstInEntry = firstInCutMark {
      if (index(of: firstInEntry) == 0) {
        return firstInEntry
      }
      else
      {
        if let firstOutEntry = firstOutCutMark
        {
          if (index(of: firstInEntry)! < index(of: firstOutEntry)!) {
            return firstInEntry
          }
          else {
            return CutEntry.InZero
          }
        }
      }
    }
    // if there are a set of bookmarks or no bookmarks
    if count > 3 || count == 0
    {
      return CutEntry.InZero
    }
    else // >0 && <= 2 bookmarks pick the first bookmark
    {
      if let entry = first {
        return entry
      }
      else { // should be technically impossible, however, belt and braces
        return CutEntry.InZero
      }
    }
  }
  
  /// Find the cut entry that preceeds the current time or is within the provivded tolerance of the
  /// time.  That is, if time is 15.99, return the 16.0 cut entry
  /// - parameter secs: target time in seconds
  /// - parameter tolerance: in seconds
  /// - returns : valid entry and sequence position or nil
  public func entryBeforeTime(_ secs: Double, tolerance: Double = 0.05) -> (entry :CutEntry, index: Int)?
  {
    var found: CutEntry? = nil
    
    // Simple serial search.  Record the highwater mark compared to target time
    // until we get a mark later than the target time
    for entry in cutsArray {
      let entrySecs = entry.asSeconds()
      if ((entrySecs - secs) <= tolerance) {
        found = entry
      }
      else {
        break
      }
    }
    if found != nil
    {
      return (found!, cutsArray.firstIndex(of: found!)!)
    }
    return nil
  }
  
  /// Routine that looks at the given program time and decide if it is in
  /// a "cut me out" section of the program and if so, return the next IN time or nil
  /// - parameter now: Core Media time structure
  /// - returns : valid IN mark time or nil
  public func programTimeAfter(_ now: CMTime) -> CMTime?
  {
    var skipCandidate = false
    let nowInSecs = now.seconds
    for entry in cutsArray {
      var markInSecs = entry.asSeconds()
      if (entry.type == MARK_TYPE.IN || entry.type == MARK_TYPE.OUT)
      {
        var markTime = CMTimeMake(value: Int64(entry.cutPts.value), timescale: TimeConstants.PTS_TIMESCALE)
        
        if (nowInSecs > markInSecs && entry.type == MARK_TYPE.OUT)
        {
          // skip ad candidate
          skipCandidate = true
          continue
        }
        
        if (nowInSecs < markInSecs && entry.type == MARK_TYPE.IN && skipCandidate) {
          markInSecs += 0.25
          markTime = CMTimeMake(value: Int64(markInSecs*1000.0)*Int64(TimeConstants.PTS_TIMESCALE/1000), timescale: TimeConstants.PTS_TIMESCALE)
          return markTime
        }
        else {
          skipCandidate = false
        }
      }
    }
    return nil
  }
  
  
  /// check that there are no IN, IN or OUT, OUT sequences present
  /// - returns: result of validation and message if flaw was found or empty string if good
  
  func validateInOut() -> (result: Bool, errorMessage: String) {
    // check in/out pairing
    var currentState = cutStates.unknown
    var goodList = true
    var message = ""
    let cutsDefined = self.inOutOnly.count > 0
    guard cutsDefined else {
      return (goodList, message)
    }
    for item in cutsArray
    {
      switch item.type {
      case .IN :
        if (currentState == .unknown || currentState == .outCut) {
          currentState = .inCut
          goodList = goodList && true
        }
        else {
          goodList = false
          message = CutsStrings.sequentialInMarks
          break
        }
      case .OUT :
        if (currentState == .unknown || currentState == .inCut ) {
          currentState = .outCut
          goodList = goodList && true
        }
        else {
          goodList = false
          message = CutsStrings.sequentialOutMarks
          break
        }
      case .BOOKMARK : fallthrough
      case .LASTPLAY :
        // does not change state
        goodList = goodList && true
      }
    }
    return (goodList, message)
  }
  
  // Simple calculation that uses the 0 based pts valued in the cuts file
  // - returns: duration of cuts to remove in seconds
  func simpleOutCutDurationInSecs() -> Double
  {
    var outDuration:Double = 0.0
    var outDurationInPTS = PtsType(0)
    
    guard (self.isCuttable) else { return outDuration }
    let inOut = self.inOutOnly
    guard (inOut.count > 0) else { return outDuration }
    
    var index = 0
    
    // leading in
    if inOut.first?.type == MARK_TYPE.IN {
      outDurationInPTS = inOut[index].cutPts
      index += 1
    }
    
    // Now in the state of having an OUT starter mark
    // now process the subsequent out/in pairs
    while (index < inOut.count-1) {
      outDurationInPTS += inOut[index+1].cutPts - inOut[index].cutPts
      index += 2
    }
    
    // Check for having a trailing OUT without matching IN,
    // that is, pruning the end of a recording
    // trailing out cut
    // FIXME: UInt64 arithmetic fails on PTS reset during recording.
    // FIXME: fails when container.ap.runtimepts returns 0 (no ap file)
    if index == inOut.count-1
    {
      // try using the derived value from the ap file
      if let apDurationInPTS = runtimePTS
      {
        if (apDurationInPTS > inOut[index].cutPts) {
          outDurationInPTS += apDurationInPTS - inOut[index].cutPts
        }
      }
      // else give up and ignor failure ?
    }
    outDuration = Double(outDurationInPTS) * TimeConstants.PTS_DURATION
    return outDuration
  }
  
  // return a cutsFile that is "well ordered".  This is defined
  // a one in which all IN and OUT marks a interleaved and contains
  // no IN,IN or OUT,OUT sequences.
  // it  starts with an OUT
  // When reducing excess entries always
  // take the earliest IN mark and the latest OUT mark
  // if the first mark is a non-zero IN mark, then insert a OUT mark at 0.0
  // if the last mark in NOT a 1.0 IN mark, insert an IN at 1.0
  // assert: array is time ordered
  func wellOrdered() -> CutsFile
  {
    var changed = false
    let newCutsFile = CutsFile(self)
    
    // check boundary conditions
    var newCutsArray = self.inOutOnly
    if !newCutsArray.isEmpty {
      if newCutsArray.first?.type != MARK_TYPE.OUT
      {
        let outStarter = CutEntry(cutPts: PtsType.zero, type: MARK_TYPE.OUT.rawValue)
        newCutsArray.insert(outStarter, at: 0)
        changed = true
      }
      if newCutsArray.last?.type != MARK_TYPE.IN
      {
        var pts = PtsType(videoDurationFromPlayer * Double(TimeConstants.PTS_TIMESCALE))
        if (pts == PtsType.zero)  // bugger
          {
            if let apPts = apLastPTS
            {
              pts = apPts
            }
            // FIXME: give up ? how
          }
        newCutsArray.append(CutEntry(cutPts: pts, type: MARK_TYPE.IN.rawValue))
        changed = true
      }
    }
    else // is empty, create a dummy 0..end
    {
        newCutsArray.append(CutEntry(cutPts: PtsType(0), type: MARK_TYPE.IN.rawValue))
        newCutsArray.append(CutEntry(cutPts: PtsType(videoDurationFromPlayer), type: MARK_TYPE.OUT.rawValue))
        changed = true
    }
    
    // now check for multiple serial INs or OUTs
    if !self.isCuttable
    {
      var entry = newCutsArray.first
      var index = 1
      while entry != nil && entry != newCutsArray.last {
        let nextEntry = newCutsArray[index]
        // check is the next is the same as the current
        if entry?.type == nextEntry.type
        {
          if entry?.type == MARK_TYPE.IN  // in remove later
          {
            newCutsArray.remove(at: index)
          }
          else // out remove earlier
          {
            newCutsArray.remove(at: index-1)
            entry = nextEntry
          }
          changed = true
        }
        else {
          if (index+1) < newCutsArray.count {
            index += 1
          }
          entry = nextEntry
        }
      }
    }
    // update copy if needed
    if (changed) {
      newCutsArray.append(contentsOf: self.bookMarks)
      newCutsArray.append(contentsOf: self.cutsArray.filter({$0.type == MARK_TYPE.LASTPLAY}))
      newCutsArray.sort()
      newCutsFile.cutsArray = newCutsArray
    }
    if !newCutsFile.isCuttable {
      print("Argh what the ....")
    }
    return newCutsFile
  }
}
