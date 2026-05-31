//
//  CutsData.swift
//  CutsEditor
//
//  Created by Alan Franklin on 3/04/2016.
//  Copyright © 2016 Alan Franklin. All rights reserved.
//
//  Defines a single entry in the .cuts file

import Foundation
import SwiftUI
import BWCore


/// struct to map over the file entries for decoding
/// NEVER modify this struct as its memory size is used to consume / decode the file data
public struct FileCutData {
  public var cutPts  : PtsType
  public var cutType : UInt32
}

