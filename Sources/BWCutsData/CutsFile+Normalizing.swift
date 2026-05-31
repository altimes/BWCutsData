//
//  File.swift
//  BWCutsData
//
//  Created by Alan Franklin on 25/5/2026.
//

import Foundation
import BWCore

///
/// Constructing N=ormalizied the marks is useful when constructing GUI elements
/// such as the jump bar under the video player that show where the various marks are
/// and the current playback point
///
extension CutsFile {
  
  public var normalizedBookmarks: [ Double] {
    get {
      return self.normalizedMarks(typeOfMark: MARK_TYPE.BOOKMARK)
    }
  }
  
  public var normalizedLastplay: [ Double] {
    get {
      return self.normalizedMarks(typeOfMark: MARK_TYPE.LASTPLAY)
    }
  }
  
  public var normalizedInMarks: [ Double] {
    get {
      return self.normalizedMarks(typeOfMark: MARK_TYPE.IN)
    }
  }
  
  public var normalizedOutMarks: [ Double] {
    get {
      return self.normalizedMarks(typeOfMark: MARK_TYPE.OUT)
    }
  }
  
  public var normalizedInOutMarks: [ Double] {
    get {
      let inOutArray = self.inOutOnly
      let markPts = inOutArray.map {$0.cutPts}
      return normalizePTSArray(ptsArray: markPts, ignorGaps: false)
    }
  }
 
  /// Get a set of IN/OUT marks for drawing the boxes for the movie cutter
  /// - returns : In/Out Marks normalized to 0..1 for display in the jump bar

  public var normalizedBoxMarks: [ Double] {
    get {
      var inOutArray = self.fullInOutOnly
      guard !inOutArray.isEmpty else { return [] }
      
      // reduce IN/IN or OUT/OUT sequences
      var index = 0
      while index < inOutArray.count-1 {
        print("index: \(index), count: \(inOutArray.count)")
        if index < inOutArray.count-1 {
          if inOutArray[index].type == inOutArray[index+1].type {
            if inOutArray[index].type == MARK_TYPE.IN {
              inOutArray.remove(at: index) // retain latest IN mark
            }
            else {
              inOutArray.remove(at: index+1) // retain earliest OUT mark
            }
          }
          else {
            index += 1
          }
        }
      }
      if inOutArray[0].type == MARK_TYPE.IN { inOutArray.remove(at: 0)}
      let markPts = inOutArray.map {$0.cutPts}
      return normalizePTSArray(ptsArray: markPts, ignorGaps: false)
    }
  }
  
  /// Normalize (0.0 ... 1.0) the selected type of cutmark
  /// Recording Gaps are ignored for bookmarks since they are not in the
  /// same PTS number scale as other embedded marks (I think)
  func normalizedMarks(typeOfMark: MARK_TYPE) -> [ Double ]
  {
    let markArray = cutsArray.filter() {$0.type == typeOfMark}
    let markPts = markArray.map {$0.cutPts}
    return normalizePTSArray(ptsArray: markPts, ignorGaps: (typeOfMark == MARK_TYPE.BOOKMARK))
  }

  /// Given array of zero based pts values, normalize them into a 0..1.0 range
  /// based on the best derived duration.  The value can be either based on actual
  /// playable duration (removing gaps) or "nominal" end_time - start_time duration
  /// ignoring gaps
  public func normalizePTSArray(ptsArray: [PtsType], ignorGaps:Bool) -> [ Double ]
  {
    // need duration >= last bookmark
    var normalizedResult = [Double]()
//    guard container?.ap != nil else {
//      return normalizedResult
//    }
//    let ap = container!.ap
    var durations: (best: Double, ap: Double) = (best: 0.0, ap: 0.0)
    if bestDurationAndApDurationInSeconds != nil {
      durations = bestDurationAndApDurationInSeconds!(0)
    }
    let range = ((durations.ap == 0) ? durations.best : durations.ap) * Double(TimeConstants.PTS_TIMESCALE)
    for pts in ptsArray
    {
      var position = 0.0
      if (apHasGaps! && !ignorGaps && runTimeFromFromPlayer != nil) {
        // ask player service for duration
        position = (Double(runTimeFromFromPlayer!(pts))) / Double(range)
      }
      else {
        position = (Double(pts))/Double(range)
      }
//      print("\(pts) div \(range) -> \(position)")
      normalizedResult.append(position)
    }
    return normalizedResult
  }
}
