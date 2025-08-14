import SwiftUI
import CoreData

struct EditSubscriptionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var subscription: Subscription

    @State private var title: String = ""
    @State private var amount: String = ""
    @State private var currency: String = Locale.current.currency?.identifier ?? "USD"
    @State private var cycleUnit: String = "month"
    @State private var cycleCount: Int = 1
    @State private var startDate: Date = Date()
    @State private var endDate: Date? = nil
    @State private var notes: String = ""
    @State private var category: String = ""
    @State private var type: String = "Outcome"

    private var isInputValid: Bool {
        !amount.isEmpty && NSDecimalNumber(string: amount) != .notANumber
    }

    var body: some View {
        NavigationView {
            SubscriptionFormView(
                title: $title,
                amount: $amount,
                currency: $currency,
                cycleUnit: $cycleUnit,
                cycleCount: $cycleCount,
                startDate: $startDate,
                endDate: $endDate,
                notes: $notes,
                category: $category,
                type: $type
            )
            .navigationTitle("Edit Subscription")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { presentationMode.wrappedValue.dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if isInputValid { save() } else { HapticManager.shared.playPeek() }
                    }
                }
            }
            .onAppear(perform: populate)
        }
        #if os(macOS)
        .frame(minWidth: 480, minHeight: 480)
        #endif
    }

    private func populate() {
        title = subscription.title ?? ""
        amount = subscription.amount?.stringValue ?? ""
    let local = Locale.current.currency?.identifier ?? "USD"
    currency = ["USD", "EUR", "CNY", "TRY", "GBP"].contains(subscription.currency ?? "") ? (subscription.currency ?? local) : local
        cycleUnit = subscription.cycleUnit ?? "month"
        cycleCount = max(1, Int(subscription.cycleCount))
        startDate = subscription.startDate ?? Date()
        endDate = subscription.endDate
        notes = subscription.notes ?? ""
        category = subscription.category ?? ""
        type = subscription.type ?? "Outcome"
    }

    private func save() {
        HapticManager.shared.playSuccess()
        presentationMode.wrappedValue.dismiss()
        // Update using the same context the object belongs to; this avoids cross-coordinator crashes
        viewContext.perform {
            subscription.title = title
            subscription.amount = NSDecimalNumber(string: amount)
            subscription.currency = currency
            subscription.cycleUnit = cycleUnit
            subscription.cycleCount = Int16(cycleCount)
            subscription.startDate = startDate
            subscription.endDate = endDate
            subscription.notes = notes
            subscription.category = category
            subscription.type = type
            do { try viewContext.save() } catch { print("Save subscription error: \(error)") }
        }
    }
}
