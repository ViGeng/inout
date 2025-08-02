import SwiftUI
import CoreData

struct DashboardView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: false)],
        animation: .default)
    private var items: FetchedResults<Item>

    private var monthlyNettoSummaries: [Date: (income: NSDecimalNumber, expenses: NSDecimalNumber, balance: NSDecimalNumber, currency: String)] {
        let calendar = Calendar.current
        var summaries: [Date: (income: NSDecimalNumber, expenses: NSDecimalNumber, balance: NSDecimalNumber, currency: String)] = [:]

        for item in items {
            guard let date = item.timestamp else { continue }
            let month = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
            var summary = summaries[month] ?? (.zero, .zero, .zero, "")

            if item.type == "Income" {
                summary.income = summary.income.adding(item.amount ?? .zero)
            } else {
                summary.expenses = summary.expenses.adding(item.amount ?? .zero)
            }
            summary.balance = summary.income.subtracting(summary.expenses)

            // Determine dominant currency for the month
            if let itemCurrency = item.currency, !itemCurrency.isEmpty {
                if summary.currency.isEmpty || item.amount?.doubleValue ?? 0 > 0 { // Simple heuristic: first currency or if amount is positive
                    summary.currency = itemCurrency
                }
            }
            summaries[month] = summary
        }
        return summaries
    }

    private var sortedMonthlyNettoSummaries: [(key: Date, value: (income: NSDecimalNumber, expenses: NSDecimalNumber, balance: NSDecimalNumber, currency: String))] {
        monthlyNettoSummaries.sorted { $0.key > $1.key }
    }

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Monthly Summaries").font(.headline)) {
                    ForEach(sortedMonthlyNettoSummaries, id: \.key) { month, summary in
                        NavigationLink(destination: MonthlySummaryDetailView(month: month)) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("\(month, formatter: monthYearFormatter)")
                                        .font(.headline)
                                    Grid(alignment: .leading, horizontalSpacing: 4, verticalSpacing: 0) {
                                        GridRow {
                                            Text("Income:")
                                                .gridColumnAlignment(.leading)
                                            Text("\(summary.income.stringValue) \(summary.currency)")
                                                .foregroundColor(.green)
                                                .gridColumnAlignment(.trailing)
                                        }
                                        GridRow {
                                            Text("Expense:")
                                                .gridColumnAlignment(.leading)
                                            Text("\(summary.expenses.stringValue) \(summary.currency)")
                                                .foregroundColor(.red)
                                                .gridColumnAlignment(.trailing)
                                        }
                                    }
                                    .font(.caption)
                                }
                                Spacer()
                                VStack(alignment: .trailing) {
                                    Text("\(summary.balance.stringValue) \(summary.currency)")
                                        .foregroundColor(summary.balance.doubleValue >= 0 ? .green : .red)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Dashboard")
        }
    }
    
    private var summaryBackgroundColor: Color {
        #if os(iOS)
        return Color(.systemGray6)
        #else
        return Color(NSColor.controlBackgroundColor)
        #endif
    }
}

struct SummaryCard: View {
    let title: String
    let amount: NSDecimalNumber
    let color: Color
    let currency: String?

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            Spacer()
            Text("\(amount.stringValue)\(currency != nil && !currency!.isEmpty ? " " + currency! : "")")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
    }
}

extension Calendar {
    func isDate(_ date: Date, inMonthOf referenceDate: Date) -> Bool {
        return self.isDate(date, equalTo: referenceDate, toGranularity: .month)
    }
}