//
//  File.swift
//  BWCutsData
//
//  Created by Alan Franklin on 25/5/2026.
//

import Foundation
import BWCore

// extractValue code from ChapGPT
extension Data {
  
  func extractValue<T>(at offset: Int, as type: T.Type) -> T {
    return self[offset ..< offset + MemoryLayout<T>.size].withUnsafeBytes { buffer in
      buffer.load(as: T.self)
    }
  }
  
  func extractCutEntry(at offset: Int) -> CutEntry {
    let tempCutEntry = self.extractValue(at: offset, as: FileCutData.self)
    let cutPtsPosition = PtsType(UInt64(bigEndian: tempCutEntry.cutPts.value))
    let typeValue = UInt32(bigEndian: tempCutEntry.cutType)
//    print("cut pts: \(cutPtsPosition), typeValue: \(typeValue)")
    let cutEntry = CutEntry(cutPts: cutPtsPosition, type: typeValue)
//    print("entry: \(cutEntry)")
    return cutEntry
  }
}

