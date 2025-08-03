import SwiftUI
import CoreData

struct EditItemView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var item: Item

    // State for the form fields, initialized from the item
    @State private var title: String = ""
    @State private var amountString: String = ""
    @State private var currency: String = ""
    @State private var type: String = ""
    @State private var category: String = ""
    @State private var notes: String = ""
    @State private var date: Date = Date()

    // Alert state
    @State private var showingAlert = false
    @State private var alertMessage = ""

    private var isInputValid: Bool {
        !amountString.isEmpty && NSDecimalNumber(string: amountString) != .notANumber
    }

    var body: some View {
        NavigationView {
            ItemFormView(
                title: $title,
                amount: $amountString,
                currency: $currency,
                type: $type,
                category: $category,
                notes: $notes,
                date: $date
            )
            .navigationTitle("Edit Item")
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
            .onAppear(perform: populateStateFromItem)
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("Save Error"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    private func populateStateFromItem() {
        title = item.title ?? ""
        amountString = item.amount?.stringValue ?? ""
        currency = item.currency ?? "USD"
        type = item.type ?? "Outcome"
        category = item.category ?? ""
        notes = item.notes ?? ""
        date = item.timestamp ?? Date()
    }

    private func saveItem() {
        withAnimation {
            // --- Amount validation ---
            if amountString.isEmpty {
                item.amount = nil
            } else {
                let potentialAmount = NSDecimalNumber(string: amountString)
                if potentialAmount == .notANumber {
                    alertMessage = "Please ensure the amount is a valid number."
                    showingAlert = true
                    return // Stop execution
                }
                item.amount = potentialAmount
            }

            // --- Update other properties ---
            item.title = title.isEmpty ? nil : title
            item.currency = currency
            item.type = type
            item.category = category
            item.notes = notes.isEmpty ? nil : notes
            item.timestamp = date

            // --- Save to Core Data ---
            do {
                try viewContext.save()
                presentationMode.wrappedValue.dismiss()
            } catch {
                alertMessage = "Failed to save item. Please try again."
                showingAlert = true
            }
        }
    }
}
