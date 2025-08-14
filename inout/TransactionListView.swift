import SwiftUI
import CoreData
import UniformTypeIdentifiers

struct TransactionListView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @State private var searchText = ""

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: false)],
        animation: .default)
    private var items: FetchedResults<Item>
    @State private var showingAddItemView = false
    @State private var showImporter = false
    @State private var showExporter = false
    @State private var exportDocument = CSVDocument(text: "")
    @State private var showAlert = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""

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
                                .contextMenu {
                                    Button(role: .destructive) {
                                        delete(item: item)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
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
                    Menu {
                        Button(action: prepareExport) {
                            Label("Export CSV", systemImage: "square.and.arrow.up")
                        }
                        Button(action: { showImporter = true }) {
                            Label("Import CSV", systemImage: "square.and.arrow.down")
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.down.on.square")
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
                    Menu {
                        Button(action: prepareExport) {
                            Label("Export CSV", systemImage: "square.and.arrow.up")
                        }
                        Button(action: { showImporter = true }) {
                            Label("Import CSV", systemImage: "square.and.arrow.down")
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.down.on.square")
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
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.commaSeparatedText, .plainText]) { result in
                switch result {
                case .success(let url):
                    importCSV(from: url)
                case .failure(let error):
            alertTitle = "Import Error"
            alertMessage = error.localizedDescription
            showAlert = true
                }
            }
            .fileExporter(isPresented: $showExporter, document: exportDocument, contentType: .commaSeparatedText, defaultFilename: defaultExportFilename()) { _ in }
        .alert(isPresented: $showAlert) { Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK"))) }
        }
    }

    private func deleteItems(for date: Date, at offsets: IndexSet) {
        withAnimation {
            if let itemsForDate = groupedItems[date] {
                offsets.map { itemsForDate[$0] }.forEach(viewContext.delete)

                do {
                    try viewContext.saveWithHaptics()
                } catch {
                    // Handle the error appropriately
                }
            }
        }
    }

    private func delete(item: Item) {
        withAnimation {
            viewContext.delete(item)
            do {
                try viewContext.saveWithHaptics()
            } catch {
                // Handle the error appropriately
            }
        }
    }
}

// MARK: - Import/Export helpers

extension TransactionListView {
    private func prepareExport() {
        let csv = CSVManager.exportItemsToCSV(Array(items))
        exportDocument = CSVDocument(text: csv)
        showExporter = true
    }

    private func importCSV(from url: URL) {
        let needsAccess = url.startAccessingSecurityScopedResource()
        defer {
            if needsAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        do {
            let data = try Data(contentsOf: url)
            guard let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) else {
                alertTitle = "Import Error"
                alertMessage = "Unable to read file as text."
                showAlert = true
                return
            }

            let bg = PersistenceController.shared.container.newBackgroundContext()
            let (imported, skipped) = try CSVManager.importItemsFromCSV(text, into: bg)
            alertTitle = "Import Complete"
            alertMessage = "Imported: \(imported)\nSkipped: \(skipped)"
            showAlert = true
        } catch {
            alertTitle = "Import Error"
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }

    private func defaultExportFilename() -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyyMMdd-HHmmss"
        return "transactions-\(df.string(from: Date())).csv"
    }
}

// MARK: - CSVDocument

struct CSVDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText, .plainText] }
    static var writableContentTypes: [UTType] { [.commaSeparatedText, .plainText] }

    var text: String

    init(text: String) { self.text = text }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents,
           let str = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) {
            text = str
        } else {
            text = ""
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = text.data(using: .utf8) ?? Data()
        return .init(regularFileWithContents: data)
    }
}
