import SwiftUI
import CoreData

struct ItemDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var item: Item

    @State private var showingEditItemView = false
    @State private var selectedPhoto: Photo? = nil

    private var photoArray: [Photo] {
        if let photos = item.photos?.array as? [Photo] {
            return photos
        }
        return []
    }

    var body: some View {
        Form {
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

            if !photoArray.isEmpty {
                Section(header: Text("Photos")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(photoArray) { photo in
                                if let pimg = PhotoManager.shared.getPhoto(for: photo) {
                                    Image(platformImage: pimg)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .cornerRadius(10)
                                        .clipped()
                                        .onTapGesture {
                                            HapticManager.shared.playPeek()
                                            selectedPhoto = photo
                                        }
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Details")
        .toolbar {
            ToolbarItem {
                Button("Edit") {
                    showingEditItemView.toggle()
                }
            }
        }
        .sheet(isPresented: $showingEditItemView) {
            EditItemView(item: item)
        }
        .sheet(item: $selectedPhoto) { photo in
            if let pimg = PhotoManager.shared.getPhoto(for: photo) {
                Image(platformImage: pimg)
                    .resizable()
                    .scaledToFit()
                    .ignoresSafeArea()
                    .onTapGesture {
                        selectedPhoto = nil
                    }
            }
        }
    }
}

