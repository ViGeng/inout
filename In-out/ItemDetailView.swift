import SwiftUI

struct ItemDetailView: View {
    let item: Item

    var body: some View {
        VStack {
            Text("Title: \(item.title ?? "No Title")")
            Text("Timestamp: \(item.timestamp!, formatter: itemFormatter)")
            Text("Amount: \(item.amount?.stringValue ?? "No Amount")")
        }
        .navigationTitle("Item Details")
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()
