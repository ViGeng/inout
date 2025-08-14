import XCTest
@testable import inout
import CoreData

final class CSVManagerTests: XCTestCase {
    func testExportThenImportRoundTrip() throws {
        // Prepare in-memory store and create sample item
        let pc = PersistenceController(inMemory: true)
        let ctx = pc.container.viewContext

        let it = Item(context: ctx)
        it.title = "Lunch, with friends"
        it.amount = NSDecimalNumber(string: "1234")
        it.currency = "USD"
        it.type = "Outcome"
        it.category = "Groceries"
        it.notes = "Paid half; great time!"
        it.timestamp = ISO8601DateFormatter().date(from: "2024-12-31T23:59:59Z")
        try ctx.save()

        // Export
        let fetch: NSFetchRequest<Item> = Item.fetchRequest()
        fetch.sortDescriptors = []
        let items = try ctx.fetch(fetch)
        let csv = CSVManager.exportItemsToCSV(items)
        XCTAssertTrue(csv.contains("title,amount,currency,type,category,notes,timestamp"))
        XCTAssertTrue(csv.contains("Lunch, with friends"))
        XCTAssertTrue(csv.contains("USD"))

        // Import into a fresh in-memory store
        let pc2 = PersistenceController(inMemory: true)
        let ctx2 = pc2.container.viewContext
        let result = try CSVManager.importItemsFromCSV(csv, into: ctx2)
        XCTAssertEqual(result.imported, 1)
        XCTAssertEqual(result.skipped, 0)
        XCTAssertEqual(result.duplicates, 0)

        let items2 = try ctx2.fetch(fetch)
        XCTAssertEqual(items2.count, 1)
        let imp = items2[0]
        XCTAssertEqual(imp.title, it.title)
        XCTAssertEqual(imp.currency, "USD")
        XCTAssertEqual(imp.type, "Outcome")
        XCTAssertEqual(imp.category, "Groceries")
        XCTAssertEqual(imp.amount, NSDecimalNumber(string: "1234"))
    }

    func testImportHeaderlessCSV() throws {
        let csv = "Lunch,123,USD,Outcome,Food,Note,2025-01-01\n"
        let pc = PersistenceController(inMemory: true)
        let ctx = pc.container.viewContext
        let result = try CSVManager.importItemsFromCSV(csv, into: ctx)
        XCTAssertEqual(result.imported, 1)
        XCTAssertEqual(result.skipped, 0)
        XCTAssertEqual(result.duplicates, 0)
    }
    
    func testImportAutomaticallyCreatesCategories() throws {
        // Prepare CSV with multiple categories
        let csv = """
        title,amount,currency,type,category,notes,timestamp
        Coffee,5.50,USD,Outcome,Beverages,Morning coffee,2025-08-13T08:30:00Z
        Salary,5000,USD,Income,Salary,Monthly salary,2025-08-01T09:00:00Z
        Groceries,125.75,USD,Outcome,Food,Weekly groceries,2025-08-12T15:00:00Z
        Freelance,800,USD,Income,Freelance,Web project,2025-08-10T14:00:00Z
        """
        
        let pc = PersistenceController(inMemory: true)
        let ctx = pc.container.viewContext
        
        // Verify no categories exist initially
        let initialCategoryFetch: NSFetchRequest<Category> = Category.fetchRequest()
        let initialCategories = try ctx.fetch(initialCategoryFetch)
        XCTAssertEqual(initialCategories.count, 0)
        
        // Import CSV
        let result = try CSVManager.importItemsFromCSV(csv, into: ctx)
        XCTAssertEqual(result.imported, 4)
        XCTAssertEqual(result.skipped, 0)
        XCTAssertEqual(result.duplicates, 0)
        
        // Verify categories were created
        let categoryFetch: NSFetchRequest<Category> = Category.fetchRequest()
        categoryFetch.sortDescriptors = [NSSortDescriptor(keyPath: \Category.name, ascending: true)]
        let categories = try ctx.fetch(categoryFetch)
        
        XCTAssertEqual(categories.count, 4)
        
        // Check specific categories
        let categoryNames = categories.compactMap { $0.name }
        let categoryTypes = categories.compactMap { $0.type }
        
        XCTAssertTrue(categoryNames.contains("Beverages"))
        XCTAssertTrue(categoryNames.contains("Salary"))
        XCTAssertTrue(categoryNames.contains("Food"))
        XCTAssertTrue(categoryNames.contains("Freelance"))
        
        // Check that categories have correct types
        if let beverageCategory = categories.first(where: { $0.name == "Beverages" }) {
            XCTAssertEqual(beverageCategory.type, "Outcome")
        }
        if let salaryCategory = categories.first(where: { $0.name == "Salary" }) {
            XCTAssertEqual(salaryCategory.type, "Income")
        }
    }
    
    func testImportDoesNotDuplicateExistingCategories() throws {
        let pc = PersistenceController(inMemory: true)
        let ctx = pc.container.viewContext
        
        // Create an existing category
        let existingCategory = Category(context: ctx)
        existingCategory.name = "Food"
        existingCategory.type = "Outcome"
        try ctx.save()
        
        // Import CSV with same category
        let csv = """
        title,amount,currency,type,category,notes,timestamp
        Lunch,50,USD,Outcome,Food,Restaurant,2025-08-13T12:00:00Z
        Dinner,75,USD,Outcome,Food,Restaurant,2025-08-13T19:00:00Z
        """
        
        let result = try CSVManager.importItemsFromCSV(csv, into: ctx)
        XCTAssertEqual(result.imported, 2)
        XCTAssertEqual(result.skipped, 0)
        XCTAssertEqual(result.duplicates, 0)
        
        // Verify only one Food category exists
        let categoryFetch: NSFetchRequest<Category> = Category.fetchRequest()
        categoryFetch.predicate = NSPredicate(format: "name == %@", "Food")
        let foodCategories = try ctx.fetch(categoryFetch)
        
        XCTAssertEqual(foodCategories.count, 1)
    }
    
    func testImportDetectsDuplicates() throws {
        let pc = PersistenceController(inMemory: true)
        let ctx = pc.container.viewContext
        
        // Create an existing transaction
        let existingItem = Item(context: ctx)
        existingItem.title = "Coffee Shop"
        existingItem.amount = NSDecimalNumber(string: "5.50")
        existingItem.currency = "USD"
        existingItem.type = "Outcome"
        existingItem.category = "Beverages"
        existingItem.timestamp = ISO8601DateFormatter().date(from: "2025-08-13T08:30:00Z")
        try ctx.save()
        
        // Import CSV with duplicate and non-duplicate transactions
        let csv = """
        title,amount,currency,type,category,notes,timestamp
        Coffee Shop,5.50,USD,Outcome,Beverages,Morning coffee,2025-08-13T08:30:15Z
        Lunch,25.00,USD,Outcome,Food,Restaurant,2025-08-13T12:00:00Z
        Coffee Shop,5.50,USD,Outcome,Beverages,Another coffee,2025-08-13T08:31:00Z
        """
        
        // Use default criteria (amount + timestamp + title)
        let result = try CSVManager.importItemsFromCSV(csv, into: ctx)
        XCTAssertEqual(result.imported, 1)  // Only "Lunch" should be imported
        XCTAssertEqual(result.skipped, 0)
        XCTAssertEqual(result.duplicates, 2) // Both coffee transactions are duplicates
        
        // Verify total items
        let fetch: NSFetchRequest<Item> = Item.fetchRequest()
        let items = try ctx.fetch(fetch)
        XCTAssertEqual(items.count, 2) // Original coffee + lunch
    }
    
    func testImportWithCustomDuplicateCriteria() throws {
        let pc = PersistenceController(inMemory: true)
        let ctx = pc.container.viewContext
        
        // Create an existing transaction
        let existingItem = Item(context: ctx)
        existingItem.title = "Grocery Store"
        existingItem.amount = NSDecimalNumber(string: "50.00")
        existingItem.currency = "USD"
        existingItem.type = "Outcome"
        existingItem.category = "Food"
        existingItem.timestamp = Date()
        try ctx.save()
        
        // Import CSV with similar transaction but different timestamp
        let csv = """
        title,amount,currency,type,category,notes,timestamp
        Grocery Store,50.00,USD,Outcome,Food,Weekly shopping,2025-08-14T10:00:00Z
        """
        
        // Custom criteria: only check amount and title (not timestamp)
        let criteria = CSVManager.DuplicateCriteria(
            checkAmount: true,
            checkTimestamp: false,
            checkTitle: true,
            checkType: false,
            checkCategory: false,
            checkCurrency: false,
            timeThreshold: 60
        )
        
        let result = try CSVManager.importItemsFromCSV(csv, into: ctx, duplicateCriteria: criteria)
        XCTAssertEqual(result.imported, 0)
        XCTAssertEqual(result.duplicates, 1) // Should be detected as duplicate based on amount + title
    }
}
