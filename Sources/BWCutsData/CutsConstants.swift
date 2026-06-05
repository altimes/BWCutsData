//
//  File.swift
//  BWCutsData
//
//  Created by Alan Franklin on 21/5/2026.
//

import Foundation

struct CutsStrings {
  static let sequentialInMarks = "Sequential IN cut Marks"
  static let sequentialOutMarks = "Sequential OUT cut Marks"
  static let noCutsDefined = "No Cuts present"
}

/// Known cut mark cases
enum cutStates {
  case
    unknown,
    inCut,
    outCut,
    bookmark,
    lastplay
}

/// Probably not need is contemporary Swift

/// Text string associated with enum MARK_TYPE
struct FieldStrings {
  static let IN = "IN"
  static let OUT = "OUT"
  static let  BOOKMARK = "BOOKMARK"
  static let LASTPLAY = "LASTPLAY"
}

/*
 from the NET
 == .cut FILES ==
 
 Also network ordered, they contain a 64bit value (PTS) and 32bit value
 (type) for each cut. (If you want file offsets, use the .ap file to look up
 the PTS values.)
 
 Type is:
 
 0 - 'in' point
 1 - 'out' point
 2 - mark
 3 - lastplay
 
 If the first 'out'-point is not preceeded by an 'in'-point, there is an
 implicit 'in' point at zero.
 
 If the there is no final 'out' point, the end-of-file is an implicit
 'out'-point.
 
 Note that the PTS values are zero-based and continouus. If you want absolute
 PTS values, you can either:
 - use the .ap file, find discontinuities, and interpolate between the APs
 - or just use the first PTS value as an offset, and work around PTS
 wraparounds. (simple method)
*/

/// Enum to capture the current set of marks that the cuts file can contain
public enum MARK_TYPE : UInt32, CaseIterable
{
  // note: UInt32 is doco --- swift thinks it knows better and uses 1 byte !!!
  // hence later convoluted code to ensure serialized file entry is 32 bits
  case IN  = 0
  case OUT = 1
  case BOOKMARK = 2
  case LASTPLAY = 3
  
  /// Return a textural value for the enum I18N'able
  
  func description () -> String {
    switch self
    {
    case .IN : return FieldStrings.IN
    case .OUT : return FieldStrings.OUT
    case .BOOKMARK : return FieldStrings.BOOKMARK
    case .LASTPLAY : return FieldStrings.LASTPLAY
    }
  }
  
  /// Given a suitable number try to return a MARK_TYPE\
  ///
  /// - parameter raw: value of enum
  /// - returns : valid enum or nil
  static func lookupOnRawValue(_ raw : UInt32) -> MARK_TYPE
  {
    switch (raw)
    {
    case IN.rawValue : return .IN
    case OUT.rawValue : return .OUT
    case BOOKMARK.rawValue : return .BOOKMARK
    case LASTPLAY.rawValue  : return .LASTPLAY
    default : return .BOOKMARK
    }
  }

  // TODO: Find better location or method to assoicate colour with field type
  /* GUI stuff should not be here  BWGuiUtils ??
  public func color() -> Color
  {
    var selected: Color
    switch self {
    case .IN:   selected = Color.green.opacity(0.7)
    case .OUT:  selected = Color.red.opacity(0.5)
    case .BOOKMARK:  selected = Color.yellow.opacity(0.9)
    case .LASTPLAY:  selected = Color.blue.opacity(0.7)
    }
    return selected
  }
   */

}
