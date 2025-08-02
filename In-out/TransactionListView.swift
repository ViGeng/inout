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

    var filteredItems: [Item] {
        items.filter { item in
            searchText.isEmpty ||
            item.title?.localizedCaseInsensitiveContains(searchText) ?? false ||
            item.category?.localizedCaseInsensitiveContains(searchText) ?? false ||
            item.notes?.localizedCaseInsensitiveContains(searchText) ?? false
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $searchText)
                    .padding(.top)

                List {
                    ForEach(filteredItems) { item in
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
                                        .foregroundColor(item.type == "Income" ? .green : .primary)
                                    Text(item.timestamp ?? Date(), formatter: itemFormatter)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                    .onDelete(perform: deleteItems)
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

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { filteredItems[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                // Handle the error appropriately
            }
        }
    }
}

struct SearchBar: View {
    @Binding var text: String

    private var backgroundColor: Color {
        #if os(iOS)
        return Color(.systemGray6)
        #else
        return Color(NSColor.controlBackgroundColor)
        #endif
    }

    var body: some View {
        HStack {
            TextField("Search", text: $text)
                .padding(7)
                .padding(.horizontal, 25)
                .background(backgroundColor)
                .cornerRadius(8)
                .overlay(
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 8)

                        if !text.isEmpty {
                            Button(action: {
                                self.text = ""
                            }) {
                                Image(systemName: "multiply.circle.fill")
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 8)
                            }
                        }
                    }
                )
                .padding(.horizontal, 10)
        }
    }
}
