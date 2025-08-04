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
                Picker("Type", selection: $type) {
                    ForEach(types, id: \.self) {
                        Text($0)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: type, perform: { newType in
                    let filteredCategories = categories.filter { $0.type == newType }
                    if !filteredCategories.contains(where: { $0.name == category }) {
                        category = filteredCategories.first?.name ?? ""
                    }
                })

                TextField("Title", text: $title)
                TextField("Amount", text: $amount)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
                Picker("Currency", selection: $currency) {
                    ForEach(Locale.commonISOCurrencyCodes, id: \.self) { currencyCode in
                        Text(currencyCode).tag(currencyCode)
                    }
                }
                Picker("Category", selection: $category) {
                    ForEach(categories.filter { $0.type == type }) { category in
                        Text(category.name ?? "").tag(category.name ?? "")
                    }
                }
                TextField("Notes", text: $notes)
                DatePicker("Date", selection: $date)
            }

            Section(header: Text("Photos")) {
                PhotosPicker(selection: $selectedPhotos, maxSelectionCount: 5, matching: .images) {
                    Label("Add Photos", systemImage: "photo")
                }

                if !selectedPhotoData.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(selectedPhotoData, id: \.self) { data in
                                if let uiImage = UIImage(data: data) {
                                    photoThumbnail(data: data, uiImage: uiImage)
                                }
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            let filteredCategories = categories.filter { $0.type == type }
            if !filteredCategories.contains(where: { $0.name == category }) {
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
                ToolbarItemGroup(placement: .bottomBar) {
                    Spacer()
                    Button(action: deleteSelectedPhotos) {
                        Image(systemName: "trash")
                    }
                }
            }
        }
        .sheet(item: $photoToView) { identifiableData in
            if let uiImage = UIImage(data: identifiableData.data) {
                Image(uiImage: uiImage)
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
    private func photoThumbnail(data: Data, uiImage: UIImage) -> some View {
        Image(uiImage: uiImage)
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
