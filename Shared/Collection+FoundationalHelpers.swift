//
//  Collection+FoundationalHelpers.swift
//  XcodeUniversalSearch
//
//  Created by Sam Miller on 11/3/20.
//

import Foundation

extension Collection {
    subscript (safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
