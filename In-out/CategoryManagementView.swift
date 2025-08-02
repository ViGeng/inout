import SwiftUI
import CoreData

struct CategoryManagementView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.name, ascending: true)],
        animation: .default) private var categories: FetchedResults<Category>

    @State private var newCategoryName: String = ""
    @State private var newCategoryType: String = "Outcome"

    private let types = ["Income", "Outcome"]

    var body: some View {
        VStack {
            Form {
                Section(header: Text("Add New Category")) {
                    TextField("Name", text: $newCategoryName)
                    Picker("Type", selection: $newCategoryType) {
                        ForEach(types, id: \.self) {
                            Text($0)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    Button(action: addCategory) {
                        Text("Add Category")
                    }
                    .disabled(newCategoryName.isEmpty)
                }

                Section(header: Text("Income Categories")) {
                    ForEach(categories.filter { $0.type == "Income" }) { category in
                        Text(category.name ?? "Unnamed Category")
                    }
                    .onDelete(perform: deleteIncomeCategories)
                }

                Section(header: Text("Outcome Categories")) {
                    ForEach(categories.filter { $0.type == "Outcome" }) { category in
                        Text(category.name ?? "Unnamed Category")
                    }
                    .onDelete(perform: deleteOutcomeCategories)
                }
            }
        }
        .navigationTitle("Manage Categories")
    }

    private func addCategory() {
        withAnimation {
            let newCategory = Category(context: viewContext)
            newCategory.name = newCategoryName
            newCategory.type = newCategoryType

            do {
                try viewContext.save()
                newCategoryName = ""
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteIncomeCategories(offsets: IndexSet) {
        withAnimation {
            let incomeCategories = categories.filter { $0.type == "Income" }
            offsets.map { incomeCategories[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteOutcomeCategories(offsets: IndexSet) {
        withAnimation {
            let outcomeCategories = categories.filter { $0.type == "Outcome" }
            offsets.map { outcomeCategories[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}
