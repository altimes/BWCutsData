//
//  File.swift
//  BWCutsData
//
//  Created by Alan Franklin on 26/5/2026.
//

import Foundation

extension CutsFile {
  
  // MARK: Collection compliance
  
  public var startIndex: Int {
    get { return cutsArray.startIndex }
  }
  
  public var endIndex: Int {
    get { return cutsArray.endIndex }
  }
  
  public subscript(position: Int) -> CutEntry {
    get { return cutsArray[position] }
    set(newValue) { cutsArray[position] = newValue }
  }
  
  public func index(after i: Int) -> Int {
    return cutsArray.index(after: i)
  }
}
