import SwiftUI
import CoreData

struct ItemDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var item: Item

    @State private var isEditing = false
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        VStack {
            if isEditing {
                ItemFormView(
                    title: Binding($item.title, replacingNilWith: ""),
                    amount: Binding<String>(
                        get: { self.item.amount?.stringValue ?? "" },
                        set: { self.item.amount = NSDecimalNumber(string: $0) }
                    ),
                    currency: Binding($item.currency, replacingNilWith: "USD"),
                    type: Binding($item.type, replacingNilWith: "Outcome"),
                    category: Binding($item.category, replacingNilWith: ""),
                    notes: Binding($item.notes, replacingNilWith: ""),
                    date: Binding($item.timestamp, replacingNilWith: Date())
                )
            } else {
                List {
                    Section(header: Text("Details")) {
                        Text("Title: \(item.title ?? "No Title")")
                        Text("Amount: \(item.amount?.stringValue ?? "No Amount") \(item.currency ?? "")")
                        Text("Type: \(item.type ?? "")")
                        Text("Category: \(item.category ?? "")")
                        Text("Notes: \(item.notes ?? "")")
                        Text("Date: \(item.timestamp ?? Date(), formatter: itemFormatter)")
                    }
                }
            }
        }
        .navigationTitle("Item Details")
        .toolbar {
            ToolbarItem {
                Button(isEditing ? "Done" : "Edit") {
                    if isEditing {
                        saveContext()
                    }
                    isEditing.toggle()
                }
            }
        }
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Save Error"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            alertMessage = "Failed to save changes. Please try again."
            showingAlert = true
        }
    }
}
