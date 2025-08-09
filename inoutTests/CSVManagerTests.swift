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
        let (imported, skipped) = try CSVManager.importItemsFromCSV(csv, into: ctx2)
        XCTAssertEqual(imported, 1)
        XCTAssertEqual(skipped, 0)

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
        let (imported, skipped) = try CSVManager.importItemsFromCSV(csv, into: ctx)
        XCTAssertEqual(imported, 1)
        XCTAssertEqual(skipped, 0)
    }
}
