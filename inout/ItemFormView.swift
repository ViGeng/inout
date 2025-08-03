import SwiftUI
import CoreData

struct ItemFormView: View {
    @Binding var title: String
    @Binding var amount: String
    @Binding var currency: String
    @Binding var type: String
    @Binding var category: String
    @Binding var notes: String
    @Binding var date: Date

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.name, ascending: true)],
        animation: .default) private var categories: FetchedResults<Category>

    private let types = ["Income", "Outcome"]

    var body: some View {
        Form {
            Section(header: Text("Details")) {
                Picker("Type", selection: $type) {
                    ForEach(types, id: \.self) {
                        Text($0)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: type, perform: { newType in
                    // When type changes, ensure a valid category is selected
                    let filteredCategories = categories.filter { $0.type == newType }
                    if !filteredCategories.contains(where: { $0.name == category }) {
                        category = filteredCategories.first?.name ?? "" // Set to first valid category or empty
                    }
                })

                TextField("Title", text: $title)
                TextField("Amount", text: $amount)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
                Picker("Currency", selection: $currency) {
                    ForEach(Locale.commonISOCurrencyCodes, id: \.self) { currencyCode in
                        Text(currencyCode).tag(currencyCode)
                    }
                }
                Picker("Category", selection: $category) {
                    ForEach(categories.filter { $0.type == type }) { category in
                        Text(category.name ?? "").tag(category.name ?? "")
                    }
                }
                TextField("Notes", text: $notes)
                DatePicker("Date", selection: $date)
            }
        }
        .onAppear {
            // On appear, ensure the selected category is valid for the current type
            let filteredCategories = categories.filter { $0.type == type }
            if !filteredCategories.contains(where: { $0.name == category }) {
                category = filteredCategories.first?.name ?? "" // Set to first valid category or empty
            }
        }
    }
}
