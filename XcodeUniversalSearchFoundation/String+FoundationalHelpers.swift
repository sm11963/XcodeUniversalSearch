//
//  String+FoundationalHelpers.swift
//  XcodeUniversalSearch
//
//  Created by Sam Miller on 11/3/20.
//

import Foundation

public extension String {
    
    subscript (_ range: Range<Int>) -> Substring {
        let start = index(startIndex, offsetBy: range.startIndex)
        let end = index(startIndex, offsetBy: range.startIndex + range.count)
        return self[start..<end]
    }
}
