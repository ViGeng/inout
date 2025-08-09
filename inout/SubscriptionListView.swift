import SwiftUI
import CoreData

struct SubscriptionListView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @State private var searchText = ""

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Subscription.startDate, ascending: false)],
        animation: .default)
    private var subs: FetchedResults<Subscription>

    @State private var showingAdd = false

    private var filtered: [Subscription] {
        subs.filter { s in
            guard !searchText.isEmpty else { return true }
            return (s.title?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                   (s.notes?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                   (s.currency?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                   (s.amount?.stringValue.localizedCaseInsensitiveContains(searchText) ?? false) ||
                   (s.cycleUnit?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $searchText)
                    .padding(.top)
                List {
                    ForEach(filtered) { s in
                        NavigationLink(destination: SubscriptionDetailView(subscription: s)) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(s.title ?? "Untitled")
                                        .font(.headline)
                                    Text(summaryLine(for: s))
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                VStack(alignment: .trailing) {
                                    Text("\(s.amount?.stringValue ?? "0") \(s.currency ?? "")")
                                    if let end = s.endDate, let n = s.startDate, computeNextRenewalDate(startDate: n, cycleUnit: s.cycleUnit ?? "month", cycleCount: Int(s.cycleCount), endDate: s.endDate) == nil, Date() > end {
                                        Text("Ended")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    } else if let next = nextRenewalDate(for: s) {
                                        let isFinal = isFinalSubscriptionRenewal(nextDate: next, cycleUnit: s.cycleUnit ?? "month", cycleCount: Int(s.cycleCount), endDate: s.endDate)
                                        Text(isFinal ? "Final: \(dateOnlyFormatter.string(from: next))" : "Next: \(dateOnlyFormatter.string(from: next))")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        .contextMenu {
                            Button(role: .destructive) { delete(s) } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    .onDelete(perform: delete)
                }
            }
            .navigationTitle("Subscriptions")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingAdd = true } label: {
                        Label("Add", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAdd) { AddSubscriptionView() }
        }
    }

    private func summaryLine(for s: Subscription) -> String {
        let count = Int(s.cycleCount)
        let unit = s.cycleUnit ?? "month"
        let span = describeSubscriptionCycle(count: count, unit: unit)
        let dateStr: String = {
            if let d = s.startDate { return dateOnlyFormatter.string(from: d) }
            return "N/A"
        }()
        return "\(span) • from \(dateStr)"
    }

    private func nextRenewalDate(for s: Subscription) -> Date? {
        guard let start = s.startDate else { return nil }
        return computeNextRenewalDate(startDate: start, cycleUnit: s.cycleUnit ?? "month", cycleCount: Int(s.cycleCount), endDate: s.endDate)
    }

    private func delete(_ indexSet: IndexSet) {
        withAnimation {
            indexSet.map { filtered[$0] }.forEach(viewContext.delete)
            do { try viewContext.saveWithHaptics() } catch { }
        }
    }

    private func delete(_ s: Subscription) {
        withAnimation {
            viewContext.delete(s)
            do { try viewContext.saveWithHaptics() } catch { }
        }
    }
}
