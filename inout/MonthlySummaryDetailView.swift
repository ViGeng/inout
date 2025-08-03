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
                let convertedAmount = CurrencyConverter.convertToLocalCurrency(item.amount ?? .zero, from: item.currency ?? "")
                let currentAmount = expenses[category] ?? .zero
                expenses[category] = currentAmount.adding(convertedAmount)
            }
        }
        return expenses
    }

    private var sortedCategoryExpenses: [(key: String, value: NSDecimalNumber)] {
        categoryExpenses.sorted { $0.value.compare($1.value) == .orderedDescending }
    }

    private var defaultExpenseCurrency: String {
        return CurrencyConverter.localCurrencyCode
    }

    var body: some View {
        Form {
            Section(header: Text("Category Expenses for \(month, formatter: monthYearFormatter)").font(.headline)) {
                ForEach(sortedCategoryExpenses, id: \.key) { category, amount in
                    SummaryCard(title: category, amount: amount, color: .blue, currency: defaultExpenseCurrency)
                }
            }
        }
        .navigationTitle("Details")
    }
}
