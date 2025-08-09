import SwiftUI
import CoreData

struct SubscriptionDetailView: View {
    @ObservedObject var subscription: Subscription
    @State private var showingEdit = false

    var body: some View {
        Form {
            Section(header: Text("Subscription Details")) {
                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 12) {
                    GridRow { Text("Title").foregroundColor(.gray); Text(subscription.title ?? "N/A") }
                    GridRow { Text("Amount").foregroundColor(.gray); Text("\(subscription.amount?.stringValue ?? "0") \(subscription.currency ?? "")") }
                    GridRow { Text("Cycle").foregroundColor(.gray); Text(cycleText) }
                    GridRow { Text("From").foregroundColor(.gray); Text(subscription.startDate ?? Date(), formatter: dateOnlyFormatter) }
                    if let end = subscription.endDate { GridRow { Text("To").foregroundColor(.gray); Text(end, formatter: dateOnlyFormatter) } }
                    GridRow {
                        Text("Status").foregroundColor(.gray)
                        if let end = subscription.endDate, let start = subscription.startDate, computeNextRenewalDate(startDate: start, cycleUnit: subscription.cycleUnit ?? "month", cycleCount: Int(subscription.cycleCount), endDate: subscription.endDate) == nil, Date() > end {
                            Text("Ended")
                        } else if let start = subscription.startDate, let next = computeNextRenewalDate(startDate: start, cycleUnit: subscription.cycleUnit ?? "month", cycleCount: Int(subscription.cycleCount), endDate: subscription.endDate) {
                            let final = isFinalSubscriptionRenewal(nextDate: next, cycleUnit: subscription.cycleUnit ?? "month", cycleCount: Int(subscription.cycleCount), endDate: subscription.endDate)
                            Text(final ? "Final: \(dateOnlyFormatter.string(from: next))" : "Next: \(dateOnlyFormatter.string(from: next))")
                        } else {
                            Text("—")
                        }
                    }
                    if let notes = subscription.notes, !notes.isEmpty {
                        GridRow(alignment: .top) { Text("Notes").foregroundColor(.gray); Text(notes) }
                    }
                }
            }
        }
        .navigationTitle("Details")
        .toolbar {
            ToolbarItem { Button("Edit") { showingEdit = true } }
        }
        .sheet(isPresented: $showingEdit) { EditSubscriptionView(subscription: subscription) }
    }

    private var cycleText: String {
        describeSubscriptionCycle(count: Int(subscription.cycleCount), unit: subscription.cycleUnit ?? "month")
    }
}
