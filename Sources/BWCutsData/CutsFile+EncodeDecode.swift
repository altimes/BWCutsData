//
//  File.swift
//  BWCutsData
//
//  Created by Alan Franklin on 25/5/2026.
//
//  

import Foundation
import BWCore

extension CutsFile {
  
  /// Unravels the binary chunk of data into the required local format
  /// - parameter data: the Binary lump to be decoded
  
  public func decodeCutsData(_ data: Data)
  {
      if (debug)  {
        print("Found file ")
        print("Found file of \((data.count))! size")
      }
      
      let entries = (data.count) / MemoryLayout<FileCutData>.size
      cutsArray = [CutEntry]()
    
      // nibble through the data buffer and populate array
    let elementSize = MemoryLayout<FileCutData>.size
    var startOffset = 0
    
    for _ in 0 ..< entries
      {
        startOffset += elementSize
        let cutEntry = data.extractCutEntry(at: startOffset)
        cutsArray.append(cutEntry)
      }
      cutsArray.sort(by: <)
      modified = false
  }
  
  /// Encoder for collection. Encodes into binary form suitable for PVR
  /// - returns : data binary blob ready to writing to file
  public func encodeCutsData() -> Data
  {
    var data = Data()
    for entry in cutsArray
    {
      var entryCopy = FileCutData(cutPts: PtsType(entry.cutPts.bigEndian), cutType: entry.type.rawValue.bigEndian)
      data.append(Data(bytes: &entryCopy, count: MemoryLayout<FileCutData>.size))
    }
    return data
  }
  
  /// Save the cuts data back to disk and return result
  /// parameter filenamePath: full path to file
  /// returns: success or failure of save
  func saveAs(filenamePath: String) -> Bool
  {
    let (fileMgr, found, fullFileName) =  OSUtility.getFileManagerForFile(filenamePath)
    if (found) {
      let cutsData = encodeCutsData()
      let fileWritten = fileMgr.createFile(atPath: fullFileName, contents: cutsData, attributes: nil)
      if (fileWritten && debug) {
        print(MessageStrings.DID_WRITE_FILE)
      }
      if (fileWritten) {
        modified = false
        // update cache to match
        if let cache = cache {
          cache.update(cutsData, forKey: fullFileName)
        }
//        container!.updateValueInCache( cutsData, forKey: fullFileName)
      }
      return fileWritten
    }
    return false
  }

}
