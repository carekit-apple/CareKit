/*
 Copyright (c) 2020, Apple Inc. All rights reserved.
 
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
import SwiftUI

/// A card that displays a header view, multi-line label, and a completion button.
///
/// In CareKit, this view is intended to display a particular event for a task. The state of the button indicates the completion state of the event.
///
/// # Style
/// The card supports styling using `careKitStyle(_:)`.
///
/// ```
///     +-------------------------------------------------------+
///     | +------+                                              |
///     | | icon | [title]                       [detail        |
///     | | img  | [detail]                       disclosure]   |
///     | +------+                                              |
///     |                                                       |
///     |  --------------------------------------------------   |
///     |                                                       |
///     |  +-------------------------------------------------+  |
///     |  | [title]                                   [img] |  |
///     |  +-------------------------------------------------+  |
///     |  +-------------------------------------------------+  |
///     |  | [title]                                   [img] |  |
///     |  +-------------------------------------------------+  |
///     |                         .                             |
///     |                         .                             |
///     |                         .                             |
///     |  +-------------------------------------------------+  |
///     |  | [title]                                   [img] |  |
///     |  +-------------------------------------------------+  |
///     |                                                       |
///     |  [instructions]                                       |
///     +-------------------------------------------------------+
/// ```
public struct ChecklistTaskView<Header: View, Content: View>: View {
    // MARK: - Properties

    @Environment(\.careKitStyle) private var style
    @Environment(\.isCardEnabled) private var isCardEnabled

    private let isHeaderPadded: Bool
    private let isContentPadded: Bool
    private let header: Header
    private let content: Content
    private let instructions: Text?

    public var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: style.dimension.directionalInsets1.top) {
                VStack { header }
                    .if(isCardEnabled && isHeaderPadded) { $0.padding([.horizontal, .top]) }
                VStack { content }
                    .if(isCardEnabled && isContentPadded) { $0.padding([.horizontal]) }
                    // If this is the last view in the VStack, add padding to the bottom.
                    .if(instructions == nil && isCardEnabled && isContentPadded) { $0.padding([.bottom]) }
                
                instructions?
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .if(isCardEnabled) { $0.padding([.horizontal, .bottom]) }
            }
        }
    }

    // MARK: - Init

    /// Create an instance.
    /// - Parameters:
    ///   - instructions: Instructions text to display under the header.
    ///   - header: Header to inject at the top of the card. Specified content will be stacked vertically.
    ///   - content: View to inject under the header. Specified content will be stacked vertically.
    public init(
        instructions: Text? = nil,
        @ViewBuilder header: () -> Header,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            isHeaderPadded: false,
            isContentPadded: false,
            instructions: instructions,
            header: header,
            content: content
        )
    }

    init(
        isHeaderPadded: Bool,
        isContentPadded: Bool,
        instructions: Text? = nil,
        @ViewBuilder header: () -> Header,
        @ViewBuilder content: () -> Content
    ) {
        self.isHeaderPadded = isHeaderPadded
        self.isContentPadded = isContentPadded
        self.instructions = instructions
        self.header = header()
        self.content = content()
    }
}

public extension ChecklistTaskView where Header == _ChecklistTaskViewHeader {
    /// Create an instance.
    /// - Parameters:
    ///   - title: Title text to display in the header.
    ///   - detail: Detail text to display in the header.
    ///   - instructions: Instructions text to display under the header.
    ///   - content: View to inject under the header. Specified content will be stacked vertically.
    init(
        title: Text,
        detail: Text? = nil,
        instructions: Text? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            isHeaderPadded: true,
            isContentPadded: false,
            instructions: instructions,
            header: {
                _ChecklistTaskViewHeader(title: title, detail: detail)
            },
            content: content
        )
    }
}

public extension ChecklistTaskView {
    /// Create an instance.
    /// - Parameter instructions: Instructions text to display under the header.
    /// - Parameter items: Items to display in the checklist.
    /// - Parameter action: Action to perform when the button is tapped.
    /// - Parameter header: Header to inject at the top of the card. Specified content will be stacked vertically.
    init<Item : ChecklistItemIdentifiable, ChecklistContent : View>(
        items: [Item],
        action: @escaping (Item) -> Void = { _ in },
        instructions: Text? = nil,
        @ViewBuilder header: () -> Header,
        @ViewBuilder content: @escaping (Item) -> ChecklistContent
    ) where Content == _ChecklistTaskViewContent<Item, ChecklistContent> {
        self.init(
            isHeaderPadded: false,
            isContentPadded: true,
            instructions: instructions,
            header: header,
            content: {
                _ChecklistTaskViewContent(items: items, action: action, content: content)
            }
        )
    }
}

public extension ChecklistTaskView where Header == _ChecklistTaskViewHeader {
    /// Create an instance.
    /// - Parameter title: Title text to display in the header.
    /// - Parameter detail: Detail text to display in the header.
    /// - Parameter items: Items to display in the checklist.
    /// - Parameter instructions: Instructions text to display under the header.
    /// - Parameter action: Action to perform when the button is tapped.
    init<Item : ChecklistItemIdentifiable, ChecklistContent : View>(
        title: Text,
        detail: Text? = nil,
        items: [Item],
        action: @escaping (Item) -> Void = { _ in },
        instructions: Text? = nil,
        @ViewBuilder content: @escaping (Item) -> ChecklistContent
    ) where Content == _ChecklistTaskViewContent<Item, ChecklistContent> {
        self.init(
            isHeaderPadded: true,
            isContentPadded: true,
            instructions: instructions,
            header: {
                _ChecklistTaskViewHeader(title: title, detail: detail)
            }, content: {
                _ChecklistTaskViewContent(items: items, action: action, content: content)
            }
        )
    }
}

/// The default header used by a `ChecklistTaskView`.
public struct _ChecklistTaskViewHeader: View {

    @Environment(\.careKitStyle) private var style

    fileprivate let title: Text
    fileprivate let detail: Text?

    public var body: some View {
        VStack(alignment: .leading, spacing: style.dimension.directionalInsets1.top) {
            HeaderView(title: title, detail: detail)
            Divider()
        }
    }
}

/// The default content used by an `ChecklistTaskView`.
public struct _ChecklistTaskViewContent<Item : ChecklistItemIdentifiable, Content : View>: View {
    @Environment(\.sizeCategory) private var sizeCategory

    @OSValue<CGFloat>(values: [.watchOS: 4], defaultValue: 8) private var padding

    fileprivate let items: [Item]
    fileprivate let action: (Item) -> Void
    fileprivate let content: (Item) -> Content

    public var body: some View {
        ForEach(items) { item in
            Button(action: { action(item) }) {
                HStack {
                    content(item)
                    Spacer()
                    Image(systemName: item.isComplete ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(.accentColor)
                }
                .padding(.vertical, padding)
                Divider()
            }.buttonStyle(NoHighlightStyle())
        }
    }
}

/// Protocol used to identify items in the checklist.
public protocol ChecklistItemIdentifiable : Identifiable {
    /// True if checklist item is complete.
    var isComplete: Bool { get }
}

#if DEBUG
struct ChecklistItem : ChecklistItemIdentifiable {
    let id: Int
    let title: String
    let isImportant: Bool
    var isComplete: Bool
}

struct ChecklistTaskViewExample : View {
    @State
    var items = [
        ChecklistItem(id: 0, title: "Item 1", isImportant: false, isComplete: false),
        ChecklistItem(id: 1, title: "Item 2", isImportant: true, isComplete: false),
        ChecklistItem(id: 2, title: "Item 3", isImportant: false, isComplete: true),
    ]
    
    func selected(item selectedItem: ChecklistItem) {
        items = items.map { item in
            guard item.id == selectedItem.id else {
                return item
            }
            
            var item = item
            item.isComplete.toggle()
            return item
        }
    }
    
    var body: some View {
        VStack {
            ChecklistTaskView(
                title: Text("Title"),
                detail: Text("Detail"),
                items: items,
                action: selected(item:),
                instructions: Text("Instructions")
            ) { item in
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(item.isImportant ? .yellow : .clear)
                    Text(item.title)
                        .font(.subheadline)
                }
            }
        }
        .padding()
    }
}

struct ChecklistTaskView_Previews: PreviewProvider {
    static var previews: some View {
        ChecklistTaskViewExample()
    }
}
#endif
