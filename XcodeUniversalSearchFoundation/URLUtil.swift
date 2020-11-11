//
//  URLUtil.swift
//  XcodeUniversalSearchFoundation
//
//  Created by Sam Miller on 11/11/20.
//

import Foundation

public enum URLUtil {
    
    // MARK: - API
    
    public static func removePercentEncoding(from string: String) -> String? {
        let nonPercentSelectionToken = "{{selection_token}}"
        return string
            .replacingOccurrences(of: Self.selectionToken, with: nonPercentSelectionToken)
            .removingPercentEncoding?
            .replacingOccurrences(of: nonPercentSelectionToken, with: Self.selectionToken)
    }
    
    
    // MARK: - Private
    
    private static let selectionToken = "%s"
}
