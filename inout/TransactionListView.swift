import SwiftUI
import CoreData

struct TransactionListView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @State private var searchText = ""

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: false)],
        animation: .default)
    private var items: FetchedResults<Item>
    @State private var showingAddItemView = false

    private var groupedItems: [Date: [Item]] {
        groupItemsByDate(items: filteredItems)
    }

    private var sortedGroupedItems: [(Date, [Item])] {
        groupedItems.sorted { $0.key > $1.key }
    }

    var filteredItems: [Item] {
        items.filter { item in
            searchText.isEmpty ||
            item.title?.localizedCaseInsensitiveContains(searchText) ?? false ||
            item.category?.localizedCaseInsensitiveContains(searchText) ?? false ||
            item.notes?.localizedCaseInsensitiveContains(searchText) ?? false ||
            item.currency?.localizedCaseInsensitiveContains(searchText) ?? false ||
            (item.amount?.stringValue.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $searchText)
                    .padding(.top)

                List {
                    ForEach(sortedGroupedItems, id: \.0) { (date, items) in
                        Section(header: Text(date, style: .date)) {
                            ForEach(items) { item in
                                NavigationLink(destination: ItemDetailView(item: item)) {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(item.title ?? "No Title")
                                                .font(.headline)
                                            Text(item.category ?? "No Category")
                                                .font(.subheadline)
                                        }
                                        Spacer()
                                        VStack(alignment: .trailing) {
                                            Text("\(item.amount?.stringValue ?? "") \(item.currency ?? "")")
                                                .foregroundColor(item.type == "Income" ? .green : .blue)
                                            Text(item.timestamp ?? Date(), formatter: itemFormatter)
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                            }
                            .onDelete(perform: { indexSet in
                                deleteItems(for: date, at: indexSet)
                            })
                        }
                    }
                }
            }
            .navigationTitle("Transactions")
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: CategoryManagementView()) {
                        Label("Manage Categories", systemImage: "list.bullet")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddItemView.toggle() }) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
                #else
                ToolbarItem {
                    NavigationLink(destination: CategoryManagementView()) {
                        Label("Manage Categories", systemImage: "list.bullet")
                    }
                }
                ToolbarItem {
                    Button(action: { showingAddItemView.toggle() }) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
                #endif
            }
            .sheet(isPresented: $showingAddItemView) {
                AddItemView()
            }
        }
    }

    private func deleteItems(for date: Date, at offsets: IndexSet) {
        withAnimation {
            if let itemsForDate = groupedItems[date] {
                offsets.map { itemsForDate[$0] }.forEach(viewContext.delete)

                do {
                    try viewContext.save()
                } catch {
                    // Handle the error appropriately
                }
            }
        }
    }
}
