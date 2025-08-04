import SwiftUI
import CoreData

struct AddItemView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode

    @State private var title: String = ""
    @State private var amount: String = ""
    @State private var currency: String = Locale.current.currency?.identifier ?? "USD"
    @State private var type: String = "Outcome"
    @State private var category: String = ""
    @State private var notes: String = ""
    @State private var date: Date = Date()
    @State private var showingAlert = false
    @State private var alertMessage = ""

    private var isInputValid: Bool {
        !amount.isEmpty && NSDecimalNumber(string: amount) != .notANumber
    }

    var body: some View {
        NavigationView {
            ItemFormView(
                title: $title,
                amount: $amount,
                currency: $currency,
                type: $type,
                category: $category,
                notes: $notes,
                date: $date
            )
            .navigationTitle("Add New Item")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if isInputValid {
                            saveItem()
                        } else {
                            alertMessage = "Please ensure the amount is a valid number."
                            showingAlert = true
                        }
                    }
                }
            }
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("Invalid Input"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    private func saveItem() {
        withAnimation {
            let newItem = Item(context: viewContext)
            newItem.timestamp = date
            newItem.title = title
            newItem.amount = NSDecimalNumber(string: amount)
            newItem.currency = currency
            newItem.type = type
            newItem.category = category
            newItem.notes = notes

            do {
                try viewContext.saveWithHaptics()
                presentationMode.wrappedValue.dismiss()
            } catch {
                alertMessage = "Failed to save item. Please try again."
                showingAlert = true
            }
        }
    }
}
