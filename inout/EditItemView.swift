import SwiftUI
import CoreData

struct EditItemView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var item: Item

    // State for the form fields
    @State private var title: String = ""
    @State private var amountString: String = ""
    @State private var currency: String = Locale.current.currency?.identifier ?? "USD"
    @State private var type: String = ""
    @State private var category: String = ""
    @State private var notes: String = ""
    @State private var date: Date = Date()
    @State private var selectedPhotoData: [Data] = []
    @State private var existingPhotos: [Photo] = []

    // Alert state
    @State private var showingAlert = false
    @State private var alertMessage = ""

    private var isInputValid: Bool {
        !amountString.isEmpty && NSDecimalNumber(string: amountString) != .notANumber
    }

    var body: some View {
    NavigationView {
            ItemFormView(
                title: $title,
                amount: $amountString,
                currency: $currency,
                type: $type,
                category: $category,
                notes: $notes,
                date: $date,
                selectedPhotoData: $selectedPhotoData
            )
            .navigationTitle("Edit Item")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if isInputValid {
                            saveItem()
                        } else {
                            alertMessage = "Please ensure the amount is a valid number."
                            showingAlert = true
                        }
                    }
                }
            }
            .onAppear(perform: populateStateFromItem)
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("Save Error"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
    }
    #if os(macOS)
    .frame(minWidth: 560, idealWidth: 720, minHeight: 640)
    #endif
    }

    private func populateStateFromItem() {
        title = item.title ?? ""
        amountString = item.amount?.stringValue ?? ""
    let local = Locale.current.currency?.identifier ?? "USD"
    currency = ["USD", "EUR", "CNY", "TRY", "GBP"].contains(item.currency ?? "") ? (item.currency ?? local) : local
        type = item.type ?? "Outcome"
        category = item.category ?? ""
        notes = item.notes ?? ""
        date = item.timestamp ?? Date()
        
        if let photos = item.photos?.array as? [Photo] {
            existingPhotos = photos
            selectedPhotoData = existingPhotos.compactMap { photo in
                PhotoManager.shared.getPhoto(for: photo)?.toJPEGData()
            }
        }
    }

    private func saveItem() {
        // Provide immediate feedback
        HapticManager.shared.playSuccess()
        presentationMode.wrappedValue.dismiss()

        // Perform the save on the same context to avoid cross-coordinator issues
        viewContext.perform {
            let itemInContext = item

            if amountString.isEmpty {
                itemInContext.amount = nil
            } else {
                let potentialAmount = NSDecimalNumber(string: amountString)
                if potentialAmount == .notANumber {
                    // This case should be handled by the UI validation,
                    // but as a safeguard, we return.
                    return
                }
                itemInContext.amount = potentialAmount
            }

            itemInContext.title = title.isEmpty ? nil : title
            itemInContext.currency = currency
            itemInContext.type = type
            itemInContext.category = category
            itemInContext.notes = notes.isEmpty ? nil : notes
            itemInContext.timestamp = date

            let currentPhotoData = (itemInContext.photos?.array as? [Photo] ?? []).compactMap { PhotoManager.shared.getPhoto(for: $0)?.toJPEGData() }
            let photosToDelete = (itemInContext.photos?.array as? [Photo] ?? []).filter { photo in
                guard let data = PhotoManager.shared.getPhoto(for: photo)?.toJPEGData() else { return false }
                return !selectedPhotoData.contains(data)
            }

            for photo in photosToDelete {
                PhotoManager.shared.deletePhoto(photo: photo, context: viewContext)
            }
            
            let newPhotoData = selectedPhotoData.filter { data in
                !currentPhotoData.contains(data)
            }

            for data in newPhotoData {
                if let image = PlatformImage.fromData(data) {
                    _ = PhotoManager.shared.savePhoto(image: image, for: itemInContext, context: viewContext)
                }
            }

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                print("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}
