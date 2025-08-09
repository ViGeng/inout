import SwiftUI
import CoreData

struct AddSubscriptionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode

    @State private var title: String = ""
    @State private var amount: String = ""
    @State private var currency: String = Locale.current.currency?.identifier ?? "USD"
    @State private var cycleUnit: String = "month"
    @State private var cycleCount: Int = 1
    @State private var startDate: Date = Date()
    @State private var endDate: Date? = nil
    @State private var notes: String = ""

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
                notes: $notes
            )
            .navigationTitle("Add Subscription")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { presentationMode.wrappedValue.dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if isInputValid { save() } else { HapticManager.shared.playPeek() }
                    }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 480, minHeight: 480)
        #endif
    }

    private func save() {
        HapticManager.shared.playSuccess()
        presentationMode.wrappedValue.dismiss()
        // Save using the same context as the UI to avoid cross-container issues in previews
        viewContext.perform {
            let s = Subscription(context: viewContext)
            s.title = title
            s.amount = NSDecimalNumber(string: amount)
            s.currency = currency
            s.cycleUnit = cycleUnit
            s.cycleCount = Int16(cycleCount)
            s.startDate = startDate
            s.endDate = endDate
            s.notes = notes
            do { try viewContext.save() } catch { print("Save subscription error: \(error)") }
        }
    }
}
