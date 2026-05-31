//
//  File.swift
//  BWCutsData
//
//  Created by Alan Franklin on 21/5/2026.
//

import Foundation
import BWCore

public struct  CutEntry: Identifiable, Equatable, Comparable {
  /// to facilitate use with ForEach
  public let id = UUID()
  /// Presentation Time Stamp UInt64
  public var cutPts  : PtsType
  /// type of a cut mark
  public var type : MARK_TYPE
  
  /// designated initializer
  init(cutPts:PtsType, type: UInt32)
  {
    self.cutPts = cutPts
    self.type = MARK_TYPE.lookupOnRawValue(type)
  }
  
  /// Constructor that masks underlying values for cut types
  init(cutPts: PtsType, mark: MARK_TYPE)
  {
    self.cutPts = cutPts
    self.type = mark
  }
  
  /// A useful "0" entry for IN marks - ie start of recording
  static var InZero: CutEntry {
    get {
      return CutEntry(cutPts: PtsType(0), type: MARK_TYPE.IN.rawValue)
    }
  }
  
  // debug support functions
  /// Convert to string with hex values
  func asHex () -> String{
    let hexRep = String(format: "%16.16lx:%8.8x", cutPts.value, type.rawValue)
    return hexRep
  }
  
  /// Convert to string with decimal values
  func asDecimal () -> String{
    let decimalRep = String(format: "%ld : %ld" , cutPts.value, type.rawValue)
    return decimalRep
  }
  
  /// Convert PTS to seconds
  func asSeconds() -> Double
  {
    return Double(self.cutPts.value) * TimeConstants.PTS_DURATION
  }
  
  /// Convert N seconds in to HH:MM:SS[.ss] format for display
  static func hhMMssFromSeconds(_ seconds: Double, resolution:Double) -> String
  {
    var inputSeconds = seconds
    var remainderSeconds = inputSeconds.truncatingRemainder(dividingBy: 60.0)
    // rounding
    if (60.0/resolution - remainderSeconds/resolution) < 0.5 {
      remainderSeconds = 0.0
      inputSeconds += 0.5/resolution
    }
    let minutes = inputSeconds / 60.0
    
    let hours = minutes / 60.0
    let days = hours / 24.0
    let intMinutes = Int(minutes) % 60
    let intHours = Int(hours) % 24
    let intDays = Int(days)
    // compose significant elements only
    var result = String.init(format: "%04.2f", remainderSeconds)
    if (intMinutes > 0  || intHours>0 || intDays > 0) {
      result = String.init(format: "%2.2d:\(result)", intMinutes)
    }
    if (intHours > 0 || intDays > 0)
    {
      result = String.init(format: "%2.2d:%@", intHours, result)
    }
    if (intDays>0) {
      result = String.init(format: "%d:%@", intDays, result)
    }
    return result
  }
  
  /// Convert N seconds in to HH:MM:SS.ss format for display
  public static func hhMMssFromSeconds(_ seconds: Double) -> String
  {
    var inputSeconds = seconds
    var remainderSeconds = inputSeconds.truncatingRemainder(dividingBy: 60.0)
    if (60.0 - remainderSeconds) < 0.5 {
      remainderSeconds = 0.0
      inputSeconds += 0.5
    }
    let minutes = inputSeconds / 60.0
    
    let hours = minutes / 60.0
    let days = hours / 24.0
    let intMinutes = Int(minutes) % 60
    let intHours = Int(hours) % 24
    let intDays = Int(days)
    // compose significant elements only
    var result = String.init(format: "%02.0f", remainderSeconds)
    if (intMinutes > 0  || intHours>0 || intDays > 0) {
      result = String.init(format: "%2.2d:\(result)", intMinutes)
    }
    if (intHours > 0 || intDays > 0)
    {
      result = String.init(format: "%2.2d:%@", intHours, result)
    }
    if (intDays>0) {
      result = String.init(format: "%d:%@", intDays, result)
    }
    return result
  }
  
  /// Return entry as printable string
  func asString() -> String {
    if let markType = MARK_TYPE(rawValue: type.rawValue) {
      return "\(markType) " + self.cutPts.hhMMss
    }
    else {
      return "Unknown Mark Type code \(type) " + self.cutPts.hhMMss
    }
  }
  
  /// Return entry with fine numeric detail
  func asStringDecimal() -> String {
    if let markType = MARK_TYPE(rawValue: type.rawValue) {
      let timeStamp = String(format:"%ld", self.cutPts.value)
      return "\(markType) " + timeStamp
    }
    else {
      return "Unknown Mark Type code \(type) " + self.cutPts.hhMMss
    }

  }
  
  /// structure with PTS and MARK_TYPE
  /// and sundry supporting functions to convert
  /// textural formats, perform comparions etc.

  /// Operator equals
  public static func == (lhs: CutEntry, rhs: CutEntry) -> Bool
  {
    return lhs.cutPts == rhs.cutPts && lhs.type == rhs.type
  }

  /// Operator not Equals
  public static func != (c1: CutEntry, c2: CutEntry) -> Bool
  {
    return c1.cutPts != c2.cutPts || c1.type != c2.type
  }

  /// Operator less than
  public static func < (c1: CutEntry, c2: CutEntry) -> Bool
  {
    return c1.cutPts < c2.cutPts
  }

  /// Operator greater than
  public static func > (c1: CutEntry, c2: CutEntry) -> Bool
  {
    return c1.cutPts > c2.cutPts
  }

}
