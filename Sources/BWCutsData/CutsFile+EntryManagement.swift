//
//  CutsFile.swift
//  BWCutsData
//
//  Created by Alan Franklin on 25/5/2026.
//

import Foundation
import BWCore

extension CutsFile {
  
  // MARK: Array Entry Management
  
  /// Get a COPY of the cutEntry at requested sequence position in the collection.
  ///
  /// - Returns: cutEntry or nil on invalid sequence position
  /// - parameter at: sequential position in the collection
  ///
  public func entry(at index: Int) -> CutEntry?
  {
    // validate index
    if (index >= 0 && index < cutsArray.count) {
      return cutsArray[index]
    }
    else {
      return nil
    }
  }
  
  /// Add cut entry to array if it is not already present.
  ///
  /// Maintain order sorted by pts value
  ///
  /// If it is present, then simply ignor the request
  /// - parameter cutEntry: entry to add to the collection
  public func addEntry(_ cutEntry: CutEntry) -> Bool
  {
    // check if already present
    if (!cutsArray.contains(cutEntry)) {
      insert(cutEntry)
      modified = true
      return true
    }
    return false
  }
  
  /// Append cutEntry to the cuts collection and
  /// re-sort the collection.
  /// Allows duplicate entries.
  /// Maintains storage in ascending order
  /// - parameter cutEntry: entry to add to the collection
  public func insert(_ entry: CutEntry)
  {
    modified = true
    cutsArray.append(entry)
    cutsArray.sort(by: <)
    if (debug) { printCutsData() }
  }
  
  /// Test if collection has an IN or OUT Marker
  ///
  /// - returns : true or false
  public var containsINorOUT: Bool
  {
    return contains([.IN, .OUT])
  }
  
  /// Returns a Boolean value indicating whether the sequence contains markType
  /// - parameter cutOfType: case from emum (.IN, .OUT, .LASTPLAY, .BOOKMARK)
  /// - returns : true or false
  func contains(_ cutOfType: Set<MARK_TYPE>) -> Bool
  {
    return cutsArray.contains(where: { cutOfType.contains($0.type) })
  }

  /// Remove the given cutEntry from the cuts storage.
  /// Missing entry is acceptable
  ///
  /// Note that each cutEntry is identifiable, thus it needs a matching Id
  /// Simple time and type is not sufficient
  ///
  /// - parameter cutEntry: entry structure to remove
  /// - returns : true if entry was found, false if not
  public func removeEntry(_ cutEntry: CutEntry) -> Bool
  {
    guard let index = cutsArray.firstIndex(of: cutEntry) else {
      return false
    }
    cutsArray.remove(at: index)
    modified = true
    return true
  }
  
  /// Remove all marks from the collection
  public func removeAll() {
    cutsArray.removeAll()
    modified = true
  }

  /// Remove the mark a the given place in the collection sequence
  /// Silently ignor out of bounds index
  /// - parameter at: sequential position in the collection
  public func remove(at index: Int)
  {
    guard (cutsArray.count > 0 && index>=0 && index < cutsArray.count) else { return }
    cutsArray.remove(at: index)
    modified = true
  }
  
  /// Remove all entries matching the given mark type from the collection
  /// - parameter type: mark type to remove
  public func removeEntriesOfType(_ type: MARK_TYPE)
  {
    // replace with array with all marks except "type"
    cutsArray = cutsArray.filter() {!($0.type == type)}
    modified = true
  }
  
  /// Get the sequence position of the first entry that matches
  /// the given entry.  Return nil on failure to find
  /// - parameter cutEntry: entry get index of
  /// - returns : sequence position or nil
  public func index(of entry: CutEntry) -> Int?
  {
    return cutsArray.firstIndex(of: entry)
  }
}
