import SwiftUI
import CoreData

struct DashboardView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: false)],
        animation: .default)
    private var items: FetchedResults<Item>

    private var monthlySummary: (income: NSDecimalNumber, expenses: NSDecimalNumber, balance: NSDecimalNumber) {
        let calendar = Calendar.current
        let currentMonthItems = items.filter { item in
            guard let date = item.timestamp else { return false }
            return calendar.isDateInCurrentMonth(date)
        }

        let income = currentMonthItems
            .filter { $0.type == "Income" }
            .reduce(NSDecimalNumber.zero) { $0.adding($1.amount ?? .zero) }

        let expenses = currentMonthItems
            .filter { $0.type == "Outcome" }
            .reduce(NSDecimalNumber.zero) { $0.adding($1.amount ?? .zero) }

        let balance = income.subtracting(expenses)

        return (income, expenses, balance)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Monthly Summary")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                SummaryCard(title: "Income", amount: monthlySummary.income, color: .green)
                SummaryCard(title: "Expenses", amount: monthlySummary.expenses, color: .red)
                SummaryCard(title: "Balance", amount: monthlySummary.balance, color: .blue)

                Spacer()
            }
            .padding()
            .navigationTitle("Dashboard")
        }
    }
}

struct SummaryCard: View {
    let title: String
    let amount: NSDecimalNumber
    let color: Color

    var body: some View {
        VStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.gray)
            Text("\(amount.stringValue) USD")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(backgroundColor)
        .cornerRadius(10)
    }

    private var backgroundColor: Color {
        #if os(iOS)
        return Color(.systemGray6)
        #else
        return Color(NSColor.controlBackgroundColor)
        #endif
    }
}

extension Calendar {
    func isDateInCurrentMonth(_ date: Date) -> Bool {
        let now = Date()
        return self.isDate(date, equalTo: now, toGranularity: .month)
    }
}
