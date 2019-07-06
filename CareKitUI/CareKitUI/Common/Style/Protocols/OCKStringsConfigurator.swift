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

import UIKit

/// A configurator that defines constants for strings.
public protocol OCKStringsConfigurator {
    var event: String { get }
    var markCompleted: String { get }
    var completed: String { get }
    var current: String { get }
    var goal: String { get }
    var noTasks: String { get }
    var cancel: String { get }
    var delete: String { get }
    var log: String { get }
    var valueLogged: String { get }
    var address: String { get }
    var tasks: String { get }
    var charts: String { get }
    var contacts: String { get }
}

public extension OCKStringsConfigurator {
    var event: String { "Event" }
    var markCompleted: String { "Mark as Completed" }
    var completed: String { "Completed" }
    var current: String { "Current" }
    var goal: String { "Goal" }
    var noTasks: String { "No Tasks" }
    var cancel: String { "Cancel" }
    var delete: String { "Delete" }
    var log: String { "Log" }
    var valueLogged: String { "Logged" }
    var address: String { "Address" }
    var tasks: String { "Tasks" }
    var charts: String { "Charts" }
    var contacts: String { "Contacts" }
}
