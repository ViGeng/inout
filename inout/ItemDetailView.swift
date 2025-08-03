import SwiftUI
import CoreData

struct ItemDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var item: Item

    // State for the form fields
    @State private var isEditing = false
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

    var body: some View {
        Form {
            if isEditing {
                ItemFormView(
                    title: $title,
                    amount: $amountString,
                    currency: $currency,
                    type: $type,
                    category: $category,
                    notes: $notes,
                    date: $date
                )
            } else {
                Section(header: Text("Transaction Details")) {
                    Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 12) {
                        GridRow {
                            Text("Title")
                                .foregroundColor(.gray)
                            Text(item.title ?? "N/A")
                                .gridColumnAlignment(.leading)
                        }
                        GridRow {
                            Text("Amount")
                                .foregroundColor(.gray)
                            Text("\(item.amount?.stringValue ?? "0") \(item.currency ?? "")")
                                .foregroundColor(item.type == "Income" ? .green : .blue)
                        }
                        GridRow {
                            Text("Type")
                                .foregroundColor(.gray)
                            Text(item.type ?? "N/A")
                        }
                        GridRow {
                            Text("Category")
                                .foregroundColor(.gray)
                            Text(item.category ?? "N/A")
                        }
                        GridRow {
                            Text("Date")
                                .foregroundColor(.gray)
                            Text(item.timestamp ?? Date(), formatter: itemFormatter)
                        }
                        
                        if let notes = item.notes, !notes.isEmpty {
                            GridRow(alignment: .top) {
                                Text("Notes")
                                    .foregroundColor(.gray)
                                Text(notes)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Details")
        .toolbar {
            ToolbarItem {
                Button(isEditing ? "Done" : "Edit") {
                    if isEditing {
                        saveContext()
                    } else {
                        populateStateFromItem()
                    }
                    isEditing.toggle()
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

    private func populateStateFromItem() {
        title = item.title ?? ""
        amountString = item.amount?.stringValue ?? ""
        currency = item.currency ?? "USD"
        type = item.type ?? "Outcome"
        category = item.category ?? ""
        notes = item.notes ?? ""
        date = item.timestamp ?? Date()
    }

    private func saveContext() {
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
        } catch {
            alertMessage = "Failed to save changes. Please try again."
            showingAlert = true
        }
    }
}

