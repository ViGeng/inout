import SwiftUI
import CoreData

struct MonthlySummaryDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    let month: Date

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: false)],
        animation: .default)
    private var items: FetchedResults<Item>

    private var categoryExpenses: [String: NSDecimalNumber] {
        let calendar = Calendar.current
        let monthExpenses = items.filter { item in
            guard let date = item.timestamp else { return false }
            return calendar.isDate(date, inMonthOf: month) && item.type == "Outcome"
        }

        var expenses: [String: NSDecimalNumber] = [:]
        for item in monthExpenses {
            if let category = item.category {
                let currentAmount = expenses[category] ?? .zero
                expenses[category] = currentAmount.adding(item.amount ?? .zero)
            }
        }
        return expenses
    }

    private var sortedCategoryExpenses: [(key: String, value: NSDecimalNumber)] {
        categoryExpenses.sorted { $0.value.compare($1.value) == .orderedDescending }
    }

    private var defaultExpenseCurrency: String {
        let calendar = Calendar.current
        let monthExpenses = items.filter { item in
            guard let date = item.timestamp else { return false }
            return calendar.isDate(date, inMonthOf: month) && item.type == "Outcome"
        }

        var currencyTotals: [String: NSDecimalNumber] = [:]
        for item in monthExpenses {
            if let currency = item.currency {
                let currentAmount = currencyTotals[currency] ?? .zero
                currencyTotals[currency] = currentAmount.adding(item.amount ?? .zero)
            }
        }

        if let (currency, _) = currencyTotals.max(by: { $0.value.compare($1.value) == .orderedAscending }) {
            return currency
        } else {
            return "USD"
        }
    }

    var body: some View {
        Form {
            Section(header: Text("Category Expenses for \(month, formatter: monthYearFormatter)").font(.headline)) {
                ForEach(sortedCategoryExpenses, id: \.key) { category, amount in
                    SummaryCard(title: category, amount: amount, color: .red, currency: defaultExpenseCurrency)
                }
            }
        }
        .navigationTitle("Details")
    }
}
