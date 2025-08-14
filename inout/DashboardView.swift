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
            var summary = summaries[month] ?? (.zero, .zero, .zero, CurrencyConverter.localCurrencyCode)

            let convertedAmount = CurrencyConverter.convertToLocalCurrency(item.amount ?? .zero, from: item.currency ?? "")

            if item.type == "Income" {
                summary.income = summary.income.adding(convertedAmount)
            } else {
                summary.expenses = summary.expenses.adding(convertedAmount)
            }
            summary.balance = summary.income.subtracting(summary.expenses)
            summary.currency = CurrencyConverter.localCurrencyCode
            summaries[month] = summary
        }
        return summaries
    }

    private var sortedMonthlyNettoSummaries: [(key: Date, value: (income: NSDecimalNumber, expenses: NSDecimalNumber, balance: NSDecimalNumber, currency: String))] {
        monthlyNettoSummaries.sorted { $0.key > $1.key }
    }

    @State private var searchText = ""

    private var filteredSummaries: [Int: [(key: Date, value: (income: NSDecimalNumber, expenses: NSDecimalNumber, balance: NSDecimalNumber, currency: String))]] {
        let filtered = searchText.isEmpty ? sortedMonthlyNettoSummaries : sortedMonthlyNettoSummaries.filter { month, summary in
            let monthString = monthYearFormatter.string(from: month)
            let yearString = String(Calendar.current.component(.year, from: month))
            let incomeString = decimalFormatter.string(from: summary.income) ?? ""
            let expenseString = decimalFormatter.string(from: summary.expenses) ?? ""
            let balanceString = decimalFormatter.string(from: summary.balance) ?? ""

            return monthString.localizedCaseInsensitiveContains(searchText) ||
                   yearString.localizedCaseInsensitiveContains(searchText) ||
                   incomeString.localizedCaseInsensitiveContains(searchText) ||
                   expenseString.localizedCaseInsensitiveContains(searchText) ||
                   balanceString.localizedCaseInsensitiveContains(searchText)
        }

        return Dictionary(grouping: filtered) { (element) -> Int in
            return Calendar.current.component(.year, from: element.key)
        }
    }

    private var sortedYears: [Int] {
        filteredSummaries.keys.sorted(by: >)
    }

    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $searchText)
                    .padding(.top)
                List {
                    ForEach(sortedYears, id: \.self) { year in
                        Section(header: Text(String(year)).font(.headline)) {
                            ForEach(filteredSummaries[year]!, id: \.key) { month, summary in
                                NavigationLink(destination: MonthlySummaryDetailView(month: month)) {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text("\(month, formatter: monthYearFormatter)")
                                                .font(.headline)
                                            Grid(alignment: .leading, horizontalSpacing: 4, verticalSpacing: 0) {
                                                GridRow {
                                                    Text("Income:")
                                                        .gridColumnAlignment(.leading)
                                                    Text("\(decimalFormatter.string(from: summary.income) ?? "0") \(summary.currency)")
                                                        .foregroundColor(.green)
                                                        .gridColumnAlignment(.trailing)
                                                }
                                                GridRow {
                                                    Text("Outcome:")
                                                        .gridColumnAlignment(.leading)
                                                    Text("\(decimalFormatter.string(from: summary.expenses) ?? "0") \(summary.currency)")
                                                        .foregroundColor(.blue)
                                                        .gridColumnAlignment(.trailing)
                                                }
                                            }
                                            .font(.caption)
                                        }
                                        Spacer()
                                        VStack(alignment: .trailing) {
                                            Text("\(decimalFormatter.string(from: summary.balance) ?? "0") \(summary.currency)")
                                                .foregroundColor(summary.balance.doubleValue >= 0 ? .green : .red)
                                        }
                                    }
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
            Text("\(decimalFormatter.string(from: amount) ?? "0")\(currency != nil && !currency!.isEmpty ? " " + currency! : "")")
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