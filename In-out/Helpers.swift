import SwiftUI

// MARK: - Binding Extension

/// An extension to create a binding to a non-optional value from an optional source.
/// If the source's wrapped value is `nil`, it provides a default value.
/// When the binding is updated, if the new value is the same as the default, the source is set to `nil`.
extension Binding where Value: Equatable {
    init(_ source: Binding<Value?>, replacingNilWith nilValue: Value) {
        self.init(
            get: { source.wrappedValue ?? nilValue },
            set: { newValue in
                if newValue == nilValue {
                    source.wrappedValue = nil
                } else {
                    source.wrappedValue = newValue
                }
            }
        )
    }
}

// MARK: - Date Formatter

/// A shared date formatter for displaying timestamps consistently across the app.
let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
}()
