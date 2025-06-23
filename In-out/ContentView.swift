//
//  ContentView.swift
//  In-out
//
//  Created by Wei GENG on 23.06.25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext    

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: false)],
        animation: .default)
    private var items: FetchedResults<Item>
    @State private var showingAddItemView = false

    var body: some View {
        NavigationView {
            List {
                ForEach(items) { item in
                    NavigationLink {
                        ItemDetailView(item: item)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(item.title ?? "no title")
                            if let timestamp = item.timestamp {
                                Text(timestamp, formatter: itemFormatter)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .sheet(isPresented: $showingAddItemView) {
                AddItemView()
            }
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
#endif
                ToolbarItem {
                    Button(action: { showingAddItemView.toggle() }) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            Text("Select an item")
        }
    }

    private let itemFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
