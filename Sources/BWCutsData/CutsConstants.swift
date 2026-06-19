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
