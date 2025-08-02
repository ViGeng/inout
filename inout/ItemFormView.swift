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
                .onChange(of: type) {
                    // When type changes, try to set a default category for the new type
                    if let firstCategory = categories.first(where: { $0.type == type }) {
                        category = firstCategory.name ?? ""
                    } else {
                        category = "" // No categories for this type
                    }
                }

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
            // Set a default category if none is selected and categories exist for the current type
            if category.isEmpty {
                if let firstCategory = categories.first(where: { $0.type == type }) {
                    category = firstCategory.name ?? ""
                }
            }
        }
    }
}
