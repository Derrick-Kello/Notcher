//
//  AppleScriptHelper.swift
//  notcher
//

import Foundation

final class AppleScriptHelper: Sendable {
    /// Executes an AppleScript on the main thread (required for NSAppleScript reliability).
    /// Returns the result descriptor, or throws on error.
    @discardableResult
    class func execute(_ scriptText: String) async throws -> NSAppleEventDescriptor? {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                let script = NSAppleScript(source: scriptText)
                var error: NSDictionary?
                let descriptor = script?.executeAndReturnError(&error)
                if let descriptor = descriptor {
                    continuation.resume(returning: descriptor)
                } else if let error = error {
                    let code = (error[NSAppleScript.errorNumber] as? Int) ?? 1
                    let message = (error[NSAppleScript.errorMessage] as? String) ?? "Unknown AppleScript error"
                    continuation.resume(throwing: NSError(
                        domain: "AppleScriptError",
                        code: code,
                        userInfo: [NSLocalizedDescriptionKey: message]
                    ))
                } else {
                    continuation.resume(throwing: NSError(
                        domain: "AppleScriptError",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "NSAppleScript returned nil without error"]
                    ))
                }
            }
        }
    }
    
    class func executeVoid(_ scriptText: String) async {
        _ = try? await execute(scriptText)
    }
}
