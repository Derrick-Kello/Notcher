//
//  AppleScriptHelper.swift
//  notcher
//

import Foundation

final class AppleScriptHelper: Sendable {
    /// Executes an AppleScript command asynchronously using /usr/bin/osascript.
    /// This bypasses in-process AppleEvents sandbox/thread-safety restrictions.
    @discardableResult
    class func execute(_ scriptText: String) async throws -> NSAppleEventDescriptor? {
        return try await Task.detached(priority: .userInitiated) {
            let script = NSAppleScript(source: scriptText)
            var error: NSDictionary?
            if let descriptor = script?.executeAndReturnError(&error) {
                return descriptor
            }
            
            // Reliable fallback: osascript process
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            process.arguments = ["-e", scriptText]
            let pipe = Pipe()
            process.standardOutput = pipe
            try? process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !output.isEmpty {
                return NSAppleEventDescriptor(string: output)
            }
            return nil
        }.value
    }
    
    /// Executes a fire-and-forget AppleScript command without blocking.
    class func executeVoid(_ scriptText: String) {
        Task.detached(priority: .userInitiated) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            process.arguments = ["-e", scriptText]
            try? process.run()
            process.waitUntilExit()
        }
    }
}
