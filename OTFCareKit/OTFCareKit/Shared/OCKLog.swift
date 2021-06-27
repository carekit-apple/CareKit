/*
 Copyright (c) 2019, Apple Inc. All rights reserved.

 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:

 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.

 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.

 3. Neither the name of the copyright holder(s) nor the names of any contributors
 may be used to endorse or promote products derived from this software without
 specific prior written permission. No license is granted to the trademarks of
 the copyright holders even if such marks are included in this software.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
import Foundation
import os.log

public struct OCKLog {

    /// Controls the log level for all of CareKit. You may set this value from within your CareKit app.
    /// To see messages that are helpful for app developers, use `.fault` or `.error`.
    /// To see messages that are helpful for framework developers, use `.debug` or `.info`.
    public static var level: OSLogType = .debug
}

/// Prints a message to the console that may be useful to app or framework developers.
/// Messages that are intended for app developers should typically be logged at level `.error`.
/// Messages for framework developers can use any appropriate log level.
///
/// Only log messages with a level at or above the value of  the global `logLevel` variable will be displayed.
/// No log messages will be displayed when building for production.
///
/// - Parameter level: A level indicating the importance of this log message. Defaults to `.info`
/// - Parameter message: A message to the developer.
/// - Parameter error: An optional error to log.
internal func log(_ level: OSLogType = .info,
                  _ message: StaticString,
                  error: Error? = nil) {

    #if DEBUG
    guard level.rawValue >= OCKLog.level.rawValue else {
        return
    }

    os_log(message, log: .carekit, type: level)

    if let error = error {
        os_log("Error: %{private}@", log: .carekit,
               type: level, error.localizedDescription)
    }
    #endif
}

private extension OSLog {

    private static var subsystem = Bundle.main.bundleIdentifier!

    static let carekit = OSLog(subsystem: subsystem, category: "CareKit")
}
