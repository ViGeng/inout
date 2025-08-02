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
            guard let currency = item.currency else { continue }
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

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Monthly Summaries")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    ForEach(currencySummaries.keys.sorted(), id: \.self) { currency in
                        let summary = currencySummaries[currency]!
                        VStack(alignment: .leading) {
                            Text("\(currency) Summary").font(.headline)
                            SummaryCard(title: "Income", amount: summary.income, color: .green, currency: currency)
                            SummaryCard(title: "Expenses", amount: summary.expenses, color: .red, currency: currency)
                            SummaryCard(title: "Balance", amount: summary.balance, color: .blue, currency: currency)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Dashboard")
        }
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
                .font(.headline)
            Spacer()
            Text("\(amount.stringValue) \(currency)")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .padding(.vertical, 4)
    }
}

extension Calendar {
    func isDateInCurrentMonth(_ date: Date) -> Bool {
        let now = Date()
        return self.isDate(date, equalTo: now, toGranularity: .month)
    }
}
