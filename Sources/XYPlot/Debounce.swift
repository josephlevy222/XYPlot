//
//  Debounce.swift
//  XYPlot
//
//  Created by Joseph Levy on 7/11/22.
//  Based on https://github.com/Tunous/DebouncedOnChange

import SwiftUI
import Combine

extension View {

    /// Adds a modifier for this view that fires an action only when a time interval in seconds represented by
    /// `debounceTime` elapses between value changes.
    ///
    /// Each time the value changes before `debounceTime` passes, the previous action will be cancelled and the next
    /// action /// will be scheduled to run after that time passes again. This mean that the action will only execute
    /// after changes to the value /// stay unmodified for the specified `debounceTime` in seconds.
    ///
    /// - Parameters:
    ///   - value: The value to check against when determining whether to run the closure.
    ///   - debounceTime: The time in seconds to wait after each value change before running `action` closure.
    ///   - action: A closure to run when the value changes.
    /// - Returns: A view that fires an action after debounced time when the specified value changes.
    public func onChange<Value>(
        of value: Value,
        debounceTime: TimeInterval,
        perform action: @escaping (_ newValue: Value) -> Void
    ) -> some View where Value: Equatable {
        self.modifier(DebouncedChangeViewModifier(trigger: value, debounceTime: debounceTime, action: action))
    }
    
    /// Same as above but adds before action
    ///   - debounceTask: The common task for multiple Values, but can be set to a different action for each change
    ///   - action: A closure to run when the value changes.
    /// - Returns: A view that fires an action after debounced time when the specified value changes.
    public func onChange<Value>(
        of value: Value,
        debounceTime: TimeInterval,
        task: Binding< Task<Void,Never>? >,
        perform action: @escaping (_ newValue: Value) -> Void
    ) -> some View where Value: Equatable {
        self.modifier(DebouncedTaskBindingChangeViewModifier(trigger: value, debounceTime: debounceTime, debouncedTask: task, action: action))
    }
}

private struct DebouncedChangeViewModifier<Value>: ViewModifier where Value: Equatable {
    let trigger: Value
    let debounceTime: TimeInterval
    let action: (Value) -> Void

    @State private var debouncedTask: Task<Void,Never>?

    func body(content: Content) -> some View {
        content.onChange(of: trigger) { value in
            debouncedTask?.cancel()
            debouncedTask = Task.delayed(seconds: debounceTime) { @MainActor in
                action(value)
            }
        }
    }
}

private struct DebouncedTaskBindingChangeViewModifier<Value>: ViewModifier where Value: Equatable {
    let trigger: Value
    let debounceTime: TimeInterval
    @Binding var debouncedTask: Task<Void,Never>?
    let action: (Value) -> Void

    func body(content: Content) -> some View {
        content.onChange(of: trigger) { value in
            debouncedTask?.cancel()
            debouncedTask = Task.delayed(seconds: debounceTime) { @MainActor in
                action(value)
            }
        }
    }
}

extension Task {
    /// Asynchronously runs the given `operation` in its own task after the specified number of `seconds`.
    ///
    /// The operation will be executed after specified number of `seconds` passes. You can cancel the task earlier
    /// for the operation to be skipped.
    ///
    /// - Parameters:
    ///   - time: Delay time in seconds.
    ///   - operation: The operation to execute.
    /// - Returns: Handle to the task which can be cancelled.
    @discardableResult
    public static func delayed(
        seconds: TimeInterval,
        operation: @escaping @Sendable () async -> Void
    ) -> Self where Success == Void, Failure == Never {
        Self {
            do {
                try await Task<Never, Never>.sleep(nanoseconds: UInt64(seconds * 1e9))
                await operation()
            } catch {}
        }
    }
}
#if DEBUG
// e.g. when field1, 2 or 3 change the number times is incremented by one, one second later
// when field changes the three other fields are changed too but the increment task only
// runs once
struct MultiTextFields: View {
    @State var debounceTask: Task<Void,Never>?
    @State var field: String = ""
    @State var field1: String = ""
    @State var field2: String = ""
    @State var field3: String = ""
    @State var times: Int = 0
    var body: some View {
        VStack {
            HStack {
                TextField("Field", text: $field).padding()
                    .onChange(of: field, debounceTime: 1) { newField in
                        field1 = newField
                        field2 = newField
                        field3 = newField
                    }
                Text(field+" \(times)").padding()
            }
            Divider()
            HStack {
                TextField("Field1", text: $field1).padding()
                    .onChange(of: field1, debounceTime: 1, task: $debounceTask) {_ in
                        times+=1 }
                Text(field1+" \(times)").padding()
            }
            HStack {
                TextField("Field2", text: $field2).padding()
                    .onChange(of: field2, debounceTime: 1, task: $debounceTask) {_ in
                        times+=1 }
                Text(field2+" \(times)").padding()
            }
            HStack {
                TextField("Field3", text: $field3).padding()
                    .onChange(of: field3, debounceTime: 1, task: $debounceTask) {_ in
                        times+=1 }
                Text(field3+" \(times)").padding()
            }
        }
    }
}

struct View_Previews: PreviewProvider {
    static var previews: some View {
        MultiTextFields()
    }
}
//-------------------------------------------------------------------
class TextDebouncer : ObservableObject {
    @Published var debouncedText = ""
    @Published var text = ""
    public var using: TimeInterval = 1.0
    
    init() {
        $text
            .debounce(for: .seconds(using), scheduler: RunLoop.main)
            .removeDuplicates()
            .assign(to: &$debouncedText)
    }
}
#endif
