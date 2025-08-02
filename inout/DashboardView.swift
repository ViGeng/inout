import SwiftUI
import CoreData

struct DashboardView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: false)],
        animation: .default)
    private var items: FetchedResults<Item>

    private var currencySummaries: [String: (income: NSDecimalNumber, expenses: NSDecimalNumber, balance: NSDecimalNumber)] {
        let calendar = Calendar.current
        let currentMonthItems = items.filter { item in
            guard let date = item.timestamp else { return false }
            return calendar.isDateInCurrentMonth(date)
        }

        var summaries: [String: (income: NSDecimalNumber, expenses: NSDecimalNumber, balance: NSDecimalNumber)] = [:]

        for item in currentMonthItems {
            guard let currency = item.currency, !currency.isEmpty else { continue }
            var summary = summaries[currency] ?? (.zero, .zero, .zero)

            if item.type == "Income" {
                summary.income = summary.income.adding(item.amount ?? .zero)
            } else {
                summary.expenses = summary.expenses.adding(item.amount ?? .zero)
            }
            summary.balance = summary.income.subtracting(summary.expenses)
            summaries[currency] = summary
        }

        return summaries
    }
    
    private var sortedSummaries: [(key: String, value: (income: NSDecimalNumber, expenses: NSDecimalNumber, balance: NSDecimalNumber))] {
        currencySummaries.sorted { $0.key < $1.key }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Monthly Summaries")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    ForEach(sortedSummaries, id: \.key) { currency, summary in
                        VStack(alignment: .leading, spacing: 10) {
                            Text("\(currency) Summary")
                                .font(.headline)
                                .padding(.bottom, 5)
                            SummaryCard(title: "Income", amount: summary.income, color: .green, currency: currency)
                            SummaryCard(title: "Expenses", amount: summary.expenses, color: .red, currency: currency)
                            SummaryCard(title: "Balance", amount: summary.balance, color: .blue, currency: currency)
                        }
                        .padding()
                        .background(summaryBackgroundColor)
                        .cornerRadius(10)
                    }

                    Spacer()
                }
                .padding()
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
    let currency: String

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            Spacer()
            Text("\(amount.stringValue) \(currency)")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
    }
}

extension Calendar {
    func isDateInCurrentMonth(_ date: Date) -> Bool {
        let now = Date()
        return self.isDate(date, equalTo: now, toGranularity: .month)
    }
}