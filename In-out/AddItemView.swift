import SwiftUI
import CoreData

struct AddItemView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode

    @State private var title: String = ""
    @State private var amount: String = ""
    @State private var showingAlert = false

    private var isInputValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && NSDecimalNumber(string: amount) != .notANumber
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Details")) {
                    TextField("Title", text: $title)
                    TextField("Amount", text: $amount)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                    }
            }
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
                            presentationMode.wrappedValue.dismiss()
                        } else {
                            showingAlert = true
                        }
                    }
                }
            }
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("Invalid Input"),
                    message: Text("Please ensure the title is not empty and the amount is a valid number."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    private func saveItem() {
        withAnimation {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()
            newItem.title = title
            newItem.amount = NSDecimalNumber(string: amount)

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}
