//
//  URLUtil.swift
//  XcodeUniversalSearchFoundation
//
//  Created by Sam Miller on 11/11/20.
//

import Foundation

public extension String {
        
    /// Remove percent encoding first ignoring occurences of the given tokens.
    /// - note: This replaces the given tokens with known safe tokens of the form `{{ignored_token`
    func removingPercentEncoding(ignoringTokens: [String]) -> String? {
        func makeTempToken(at offset: Int) -> String { "{{ignored_token_\(offset)}" }
        
        let safeString = ignoringTokens.enumerated().reduce(self) { result, value in
            result.replacingOccurrences(of: value.element, with: makeTempToken(at: value.offset))
        }
        
        return safeString
            .removingPercentEncoding
            .map {
                ignoringTokens.enumerated().reduce($0) { result, value in
                    result.replacingOccurrences(of: makeTempToken(at: value.offset), with: value.element)
                }
            }
    }
}
