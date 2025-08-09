import SwiftUI
import CoreData

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

/// A shared number formatter for handling decimal inputs consistently.
let decimalFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = 0
    formatter.minimumFractionDigits = 0
    return formatter
}()

/// A shared date formatter for displaying timestamps consistently across the app.
let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
}()

/// A shared date-only formatter (no time) for views where time is not relevant.
let dateOnlyFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .none
    return formatter
}()

/// A shared date formatter for displaying month and year consistently across the app.
let monthYearFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMMM"
    return formatter
}()

// MARK: - Grouping Helper

/// Groups a list of items by date.
/// - Parameter items: The list of items to group.
/// - Returns: A dictionary where the keys are dates and the values are the items for that date.
func groupItemsByDate(items: [Item]) -> [Date: [Item]] {
    let calendar = Calendar.current
    let groupedItems = Dictionary(grouping: items) { (item) -> Date in
        return calendar.startOfDay(for: item.timestamp ?? Date())
    }
    return groupedItems
}

extension NSManagedObjectContext {
    func saveWithHaptics() throws {
        do {
            try deleteOrphanedPhotos()
            try save()
            HapticManager.shared.playSuccess()
        } catch {
            throw error
        }
    }

    private func deleteOrphanedPhotos() throws {
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let allPhotos = try self.fetch(fetchRequest)
        let activeFilenames = allPhotos.compactMap { $0.item != nil ? $0.filename : nil }
        
        let photoManager = PhotoManager.shared
        for photo in allPhotos {
            if photo.item == nil {
                if let filename = photo.filename, !activeFilenames.contains(filename) {
                    photoManager.deletePhoto(photo: photo, context: self)
                }
            }
        }
    }
}

// MARK: - Subscription Helpers

/// Map a textual cycle unit to Calendar.Component
func subscriptionComponent(for unit: String) -> Calendar.Component {
    switch unit.lowercased() {
    case "day", "daily": return .day
    case "week", "weekly": return .weekOfYear
    case "year", "yearly", "annually": return .year
    default: return .month
    }
}

/// Human-friendly description for a subscription cycle (e.g., "monthly", "every 3 months").
func describeSubscriptionCycle(count: Int, unit: String) -> String {
    let n = max(1, count)
    let u = unit.lowercased()
    if n == 1 {
        switch u {
        case "day": return "daily"
        case "week": return "weekly"
        case "year": return "yearly"
        default: return "monthly"
        }
    } else {
        let plural = u == "day" ? "days" : u == "week" ? "weeks" : u == "year" ? "years" : "months"
        return "every \(n) \(plural)"
    }
}

/// Compute the next renewal date given a subscription definition.
func computeNextRenewalDate(startDate: Date, cycleUnit: String, cycleCount: Int, endDate: Date?) -> Date? {
    let component = subscriptionComponent(for: cycleUnit)
    let count = max(1, cycleCount)
    let cal = Calendar.current
    // Fast-forward using dateComponents if possible
    var next = startDate
    if next < Date() {
        // Roughly estimate how many cycles have passed to jump ahead
        let estimate: Int = {
            switch component {
            case .day:
                let days = cal.dateComponents([.day], from: startDate, to: Date()).day ?? 0
                return max(0, days / count)
            case .weekOfYear:
                let weeks = cal.dateComponents([.weekOfYear], from: startDate, to: Date()).weekOfYear ?? 0
                return max(0, weeks / count)
            case .year:
                let years = cal.dateComponents([.year], from: startDate, to: Date()).year ?? 0
                return max(0, years / count)
            default:
                let months = cal.dateComponents([.month], from: startDate, to: Date()).month ?? 0
                return max(0, months / count)
            }
        }()
        if estimate > 0, let jumped = cal.date(byAdding: component, value: estimate * count, to: startDate) {
            next = jumped
        }
        while next < Date(), let advanced = cal.date(byAdding: component, value: count, to: next) {
            next = advanced
        }
    }
    if let end = endDate, next > end { return nil }
    return next
}

/// Determine whether a given next renewal is the final one before the subscription ends.
func isFinalSubscriptionRenewal(nextDate: Date, cycleUnit: String, cycleCount: Int, endDate: Date?) -> Bool {
    guard let end = endDate else { return false }
    let cal = Calendar.current
    let component = subscriptionComponent(for: cycleUnit)
    let count = max(1, cycleCount)
    guard let following = cal.date(byAdding: component, value: count, to: nextDate) else { return false }
    return following > end
}


