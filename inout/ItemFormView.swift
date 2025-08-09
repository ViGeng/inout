import SwiftUI
import CoreData
import PhotosUI

// Wrapper to make photo data identifiable for the sheet view
struct IdentifiableData: Identifiable {
    let id = UUID()
    let data: Data
}

struct ItemFormView: View {
    @Binding var title: String
    @Binding var amount: String
    @Binding var currency: String
    @Binding var type: String
    @Binding var category: String
    @Binding var notes: String
    @Binding var date: Date
    @Binding var selectedPhotoData: [Data]

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.name, ascending: true)],
        animation: .default) private var categories: FetchedResults<Category>

    private let types = ["Income", "Outcome"]
    @State private var selectedPhotos: [PhotosPickerItem] = []
    
    // State for photo management
    @State private var photosToDelete = Set<Data>()
    @State private var photoToView: IdentifiableData? = nil

    var body: some View {
        Form {
            Section(header: Text("Details")) {
                #if os(macOS)
                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
                    GridRow {
                        Text("Type").foregroundColor(.gray)
                            .frame(width: 100, alignment: .trailing)
                        Picker("", selection: $type) {
                            ForEach(types, id: \.self) { Text($0) }
                        }
                        .labelsHidden()
                        .pickerStyle(.segmented)
                    }
                    .onChange(of: type) { newType in
                        let filtered = categories.filter { $0.type == newType }
                        // Only set a default when category is empty; don't override imported/manual values
                        if category.isEmpty {
                            category = filtered.first?.name ?? ""
                        }
                    }

                    GridRow {
                        Text("Title").foregroundColor(.gray)
                            .frame(width: 100, alignment: .trailing)
                        TextField("Title", text: $title)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: .infinity)
                    }
                    GridRow {
                        Text("Amount").foregroundColor(.gray)
                            .frame(width: 100, alignment: .trailing)
                        TextField("Amount", text: $amount)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: .infinity)
                    }
                    GridRow {
                        Text("Currency").foregroundColor(.gray)
                            .frame(width: 100, alignment: .trailing)
                        Picker("", selection: $currency) {
                            ForEach(Locale.commonISOCurrencyCodes, id: \.self) { Text($0).tag($0) }
                        }
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                    }
                    GridRow {
                        Text("Category").foregroundColor(.gray)
                            .frame(width: 100, alignment: .trailing)
                        Picker("", selection: $category) {
                            ForEach(categories.filter { $0.type == type }) { cat in
                                Text(cat.name ?? "").tag(cat.name ?? "")
                            }
                        }
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                    }
                    GridRow(alignment: .top) {
                        Text("Notes").foregroundColor(.gray)
                            .frame(width: 100, alignment: .trailing)
                        TextField("Notes", text: $notes)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: .infinity)
                    }
                    GridRow {
                        Text("Date").foregroundColor(.gray)
                            .frame(width: 100, alignment: .trailing)
                        DatePicker("", selection: $date)
                            .labelsHidden()
                            .frame(maxWidth: .infinity)
                    }
                }
                #else
                Picker("Type", selection: $type) {
                    ForEach(types, id: \.self) { Text($0) }
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: type, perform: { newType in
                    let filteredCategories = categories.filter { $0.type == newType }
                    // Only auto-select when category is empty; don’t override an existing value
                    if category.isEmpty {
                        category = filteredCategories.first?.name ?? ""
                    }
                })

                TextField("Title", text: $title)
                TextField("Amount", text: $amount)
                    .keyboardType(.decimalPad)
                Picker("Currency", selection: $currency) {
                    ForEach(Locale.commonISOCurrencyCodes, id: \.self) { Text($0).tag($0) }
                }
                Picker("Category", selection: $category) {
                    ForEach(categories.filter { $0.type == type }) { category in
                        Text(category.name ?? "").tag(category.name ?? "")
                    }
                }
                TextField("Notes", text: $notes)
                DatePicker("Date", selection: $date)
                #endif
            }

            Section(header: Text("Photos")) {
                PhotosPicker(selection: $selectedPhotos, maxSelectionCount: 5, matching: .images) {
                    Label("Add Photos", systemImage: "photo")
                }

                if !selectedPhotoData.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(selectedPhotoData, id: \.self) { data in
                                if let pimg = PlatformImage.fromData(data) {
                                    photoThumbnail(data: data, platformImage: pimg)
                                }
                            }
                        }
                    }
                }
            }
    }
    #if os(macOS)
    .formStyle(.grouped)
    #endif
        .onAppear {
            let filteredCategories = categories.filter { $0.type == type }
            // Only set default if empty; keep imported/custom category strings
            if category.isEmpty {
                category = filteredCategories.first?.name ?? ""
            }
        }
        .onChange(of: selectedPhotos) { newItems in
            for item in newItems {
                item.loadTransferable(type: Data.self) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let data?):
                            if !selectedPhotoData.contains(data) {
                                self.selectedPhotoData.append(data)
                            }
                        case .success(nil):
                            break
                        case .failure(let error):
                            print("Error loading photo: \(error)")
                        }
                    }
                }
            }
        }
        .toolbar {
            if !photosToDelete.isEmpty {
                #if os(iOS)
                ToolbarItemGroup(placement: .bottomBar) {
                    Spacer()
                    Button(action: deleteSelectedPhotos) {
                        Image(systemName: "trash")
                    }
                }
                #else
                ToolbarItem {
                    Button(action: deleteSelectedPhotos) {
                        Label("Delete Selected Photos", systemImage: "trash")
                    }
                }
                #endif
            }
        }
        .sheet(item: $photoToView) { identifiableData in
            if let pimg = PlatformImage.fromData(identifiableData.data) {
                Image(platformImage: pimg)
                    .resizable()
                    .scaledToFit()
                    .ignoresSafeArea()
                    .onTapGesture {
                        photoToView = nil // Dismiss on tap
                    }
            }
        }
    }
    
    @ViewBuilder
    private func photoThumbnail(data: Data, platformImage: PlatformImage) -> some View {
        Image(platformImage: platformImage)
            .resizable()
            .scaledToFill()
            .frame(width: 100, height: 100)
            .cornerRadius(10)
            .clipped()
            .overlay(
                Group {
                    if photosToDelete.contains(data) {
                        ZStack {
                            Color.black.opacity(0.4)
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.white)
                        }
                        .cornerRadius(10)
                    }
                }
            )
            .onTapGesture {
                withAnimation {
                    if photosToDelete.contains(data) {
                        photosToDelete.remove(data)
                    } else {
                        photosToDelete.insert(data)
                    }
                    HapticManager.shared.playSelection()
                }
            }
            .onLongPressGesture {
                HapticManager.shared.playPeek()
                photoToView = IdentifiableData(data: data)
            }
    }
    
    private func deleteSelectedPhotos() {
        withAnimation {
            selectedPhotoData.removeAll { photosToDelete.contains($0) }
            photosToDelete.removeAll()
            HapticManager.shared.playSuccess()
        }
    }
}
