//
//  Persistence.swift
//  In-out
//
//  Created by Wei GENG on 23.06.25.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext

        let incomeCategories = ["Salary", "Freelance"]
        for categoryName in incomeCategories {
            let newCategory = Category(context: viewContext)
            newCategory.name = categoryName
            newCategory.type = "Income"
        }

        let outcomeCategories = ["Groceries", "Transport", "Rent"]
        for categoryName in outcomeCategories {
            let newCategory = Category(context: viewContext)
            newCategory.name = categoryName
            newCategory.type = "Outcome"
        }

        for i in 0..<10 {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()
            let isIncome = i % 3 == 0
            newItem.type = isIncome ? "Income" : "Outcome"
            newItem.title = isIncome ? "Sample Income" : "Sample Outcome"
            newItem.amount = isIncome ? NSDecimalNumber(string: "\(i * 100)") : NSDecimalNumber(string: "\(i * 10)")
            newItem.currency = "USD"
            newItem.category = isIncome ? incomeCategories[i % incomeCategories.count] : outcomeCategories[i % outcomeCategories.count]
            newItem.notes = "This is a sample note for item \(i)."
        }

        // Add transactions for last month
        for i in 0..<5 {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Calendar.current.date(byAdding: .month, value: -1, to: Date())
            let isIncome = i % 2 == 0
            newItem.type = isIncome ? "Income" : "Outcome"
            newItem.title = isIncome ? "Last Month Income" : "Last Month Outcome"
            newItem.amount = isIncome ? NSDecimalNumber(string: "\(i * 150)") : NSDecimalNumber(string: "\(i * 20)")
            newItem.currency = "EUR"
            newItem.category = isIncome ? incomeCategories[i % incomeCategories.count] : outcomeCategories[i % outcomeCategories.count]
            newItem.notes = "This is a sample note for item \(i) from last month."
        }

        // Add transactions for July (two months ago)
        for i in 0..<5 {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Calendar.current.date(byAdding: .month, value: -2, to: Date())
            let isIncome = i % 2 == 0
            newItem.type = isIncome ? "Income" : "Outcome"
            newItem.title = isIncome ? "July Income" : "July Outcome"
            newItem.amount = isIncome ? NSDecimalNumber(string: "\(i * 200)") : NSDecimalNumber(string: "\(i * 30)")
            newItem.currency = "GBP"
            newItem.category = isIncome ? incomeCategories[i % incomeCategories.count] : outcomeCategories[i % outcomeCategories.count]
            newItem.notes = "This is a sample note for item \(i) from July."
        }

        // Add transactions for last year
        for i in 0..<5 {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Calendar.current.date(byAdding: .year, value: -1, to: Date())
            let isIncome = i % 2 == 0
            newItem.type = isIncome ? "Income" : "Outcome"
            newItem.title = isIncome ? "Last Year Income" : "Last Year Outcome"
            newItem.amount = isIncome ? NSDecimalNumber(string: "\(i * 250)") : NSDecimalNumber(string: "\(i * 40)")
            newItem.currency = "JPY"
            newItem.category = isIncome ? incomeCategories[i % incomeCategories.count] : outcomeCategories[i % outcomeCategories.count]
            newItem.notes = "This is a sample note for item \(i) from last year."
        }

        // Add transactions for two years ago
        for i in 0..<5 {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Calendar.current.date(byAdding: .year, value: -2, to: Date())
            let isIncome = i % 2 == 0
            newItem.type = isIncome ? "Income" : "Outcome"
            newItem.title = isIncome ? "Two Years Ago Income" : "Two Years Ago Outcome"
            newItem.amount = isIncome ? NSDecimalNumber(string: "\(i * 300)") : NSDecimalNumber(string: "\(i * 50)")
            newItem.currency = "CNY"
            newItem.category = isIncome ? incomeCategories[i % incomeCategories.count] : outcomeCategories[i % outcomeCategories.count]
            newItem.notes = "This is a sample note for item \(i) from two years ago."
        }

        // Add transactions for three years ago
        for i in 0..<5 {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Calendar.current.date(byAdding: .year, value: -3, to: Date())
            let isIncome = i % 2 == 0
            newItem.type = isIncome ? "Income" : "Outcome"
            newItem.title = isIncome ? "Three Years Ago Income" : "Three Years Ago Outcome"
            newItem.amount = isIncome ? NSDecimalNumber(string: "\(i * 350)") : NSDecimalNumber(string: "\(i * 60)")
            newItem.currency = "AUD"
            newItem.category = isIncome ? incomeCategories[i % incomeCategories.count] : outcomeCategories[i % outcomeCategories.count]
            newItem.notes = "This is a sample note for item \(i) from three years ago."
        }

    // Sample subscriptions
    let s1 = Subscription(context: viewContext)
    s1.title = "Apple Music"
    s1.amount = NSDecimalNumber(string: "9.99")
    s1.currency = "USD"
    s1.cycleUnit = "month"
    s1.cycleCount = 1
    s1.startDate = Calendar.current.date(byAdding: .month, value: -3, to: Date())
    s1.notes = "Family plan"

    let s2 = Subscription(context: viewContext)
    s2.title = "Amazon Prime"
    s2.amount = NSDecimalNumber(string: "139")
    s2.currency = "USD"
    s2.cycleUnit = "year"
    s2.cycleCount = 1
    s2.startDate = Calendar.current.date(byAdding: .year, value: -1, to: Date())
    s2.notes = "Annual billing"

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        
        // Check if default categories exist
        let fetchRequest: NSFetchRequest<Category> = Category.fetchRequest()
        let count = (try? viewContext.count(for: fetchRequest)) ?? 0
        
        if count == 0 {
            // Create default categories
            let defaultCategories = [
                ("Salary", "Income"),
                ("Freelance", "Income"),
                ("Investment", "Income"),
                ("Rent", "Outcome"),
                ("Groceries", "Outcome"),
                ("Transport", "Outcome"),
                ("Utilities", "Outcome"),
                ("Entertainment", "Outcome")
            ]
            
            for (name, type) in defaultCategories {
                let category = Category(context: viewContext)
                category.name = name
                category.type = type
            }
            
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \\(nsError), \\(nsError.userInfo)")
            }
        }
        
        return result
    }()

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "inout")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        // Enable lightweight migrations to handle model changes such as new entities
        if let desc = container.persistentStoreDescriptions.first {
            desc.shouldMigrateStoreAutomatically = true
            desc.shouldInferMappingModelAutomatically = true
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \\(error), \\(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
