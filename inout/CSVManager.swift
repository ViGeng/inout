import Foundation
import CoreData

// MARK: - CSV Helpers

struct CSVManager {
    struct Columns {
        static let header = ["title", "amount", "currency", "type", "category", "notes", "timestamp"]
    }
    
    // Helper struct for category-type pairs
    private struct CategoryTypePair: Hashable {
        let name: String
        let type: String
    }

    // Export an array of Item to CSV string (photos are ignored)
    static func exportItemsToCSV(_ items: [Item]) -> String {
        var lines: [String] = []
        lines.append(Columns.header.joined(separator: ","))

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        for item in items {
            let title = csvEscape(item.title ?? "")
            let amount = csvEscape(item.amount?.stringValue ?? "")
            let currency = csvEscape(item.currency ?? "")
            let type = csvEscape(item.type ?? "")
            let category = csvEscape(item.category ?? "")
            let notes = csvEscape(item.notes ?? "")
            let ts = item.timestamp ?? Date()
            let timestamp = csvEscape(iso.string(from: ts))

            let row = [title, amount, currency, type, category, notes, timestamp].joined(separator: ",")
            lines.append(row)
        }

        return lines.joined(separator: "\n") + "\n"
    }

    /// Structure to hold duplicate detection criteria for CSV import
    /// When importing transactions, the system will check for duplicates based on the enabled criteria.
    /// A transaction is considered a duplicate if it matches at least 2 of the selected criteria
    /// (or all criteria if less than 2 are selected).
    struct DuplicateCriteria {
        /// Check if the transaction amount matches
        let checkAmount: Bool
        /// Check if the transaction timestamp matches (within timeThreshold)
        let checkTimestamp: Bool  
        /// Check if the transaction title matches (case-insensitive)
        let checkTitle: Bool
        /// Check if the transaction type (Income/Outcome) matches
        let checkType: Bool
        /// Check if the transaction category matches (case-insensitive)
        let checkCategory: Bool
        /// Check if the transaction currency matches
        let checkCurrency: Bool
        /// Time threshold in seconds - transactions within this time range are considered to have the same timestamp
        let timeThreshold: TimeInterval
        
        /// Default criteria: checks amount, date (same day), and type
        static let `default` = DuplicateCriteria(
            checkAmount: true,
            checkTimestamp: true,
            checkTitle: false,
            checkType: true,
            checkCategory: false,
            checkCurrency: false,
            timeThreshold: 86400 // 24 hours (same day)
        )
    }
    
    // Import Items from CSV string. Returns (imported count, skipped count, duplicates count)
    static func importItemsFromCSV(_ csv: String, 
                                    into context: NSManagedObjectContext,
                                    duplicateCriteria: DuplicateCriteria = .default) throws -> (imported: Int, skipped: Int, duplicates: Int) {
        var imported = 0
        var skipped = 0
        var duplicates = 0
        var thrownError: Error?

        context.performAndWait {
            // Handle potential UTF-8 BOM and prepare rows
            var content = csv
            if content.first == "\u{FEFF}" { content.removeFirst() }
            let rows = content.split(whereSeparator: { $0.isNewline })
            guard !rows.isEmpty else { imported = 0; skipped = 0; return }

            var startIndex = 0
            let headerFields = parseCSVRow(String(rows[0]))
            if matchesHeader(headerFields) { startIndex = 1 }

            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

            // Fallback date formats
            let dateFormats = [
                "yyyy-MM-dd'T'HH:mm:ssXXXXX",
                "yyyy-MM-dd HH:mm:ssZ",
                "yyyy-MM-dd"
            ]
            let dateFormatters: [DateFormatter] = dateFormats.map { fmt in
                let df = DateFormatter()
                df.locale = Locale(identifier: "en_US_POSIX")
                df.dateFormat = fmt
                return df
            }

            // Step 1: Collect unique category-type pairs from the CSV
            var categoryTypePairs: Set<CategoryTypePair> = []
            
            for i in startIndex..<rows.count {
                let fields = parseCSVRow(String(rows[i]))
                if fields.count < 7 { continue }
                
                let type = emptyToNil(fields[3])
                let category = emptyToNil(fields[4])
                
                if let category = category, !category.isEmpty {
                    let normalizedType: String = {
                        guard let t = type?.trimmingCharacters(in: .whitespacesAndNewlines), !t.isEmpty else { return "Outcome" }
                        if t.lowercased().hasPrefix("in") { return "Income" }
                        if t.lowercased().hasPrefix("out") { return "Outcome" }
                        return t == "Income" ? "Income" : "Outcome"
                    }()
                    
                    categoryTypePairs.insert(CategoryTypePair(name: category, type: normalizedType))
                }
            }
            
            // Step 2: Create missing categories
            createMissingCategories(categoryTypePairs, context: context)
            
            // Step 3: Fetch existing items for duplicate detection
            let existingItems = fetchExistingItems(context: context)

            // Step 4: Import items
            for i in startIndex..<rows.count {
                let fields = parseCSVRow(String(rows[i]))
                if fields.count < 7 { skipped += 1; continue }

                let title = emptyToNil(fields[0])
                let amountStr = emptyToNil(fields[1])
                let currency = emptyToNil(fields[2])
                let type = emptyToNil(fields[3])
                let category = emptyToNil(fields[4])
                let notes = emptyToNil(fields[5])
                let timestampStr = emptyToNil(fields[6])

                // Validate amount
                let amount: NSDecimalNumber? = {
                    guard let s = amountStr, !s.isEmpty else { return nil }
                    let n = NSDecimalNumber(string: s)
                    return n == .notANumber ? nil : n
                }()

                // Parse date
                let timestamp: Date = {
                    if let ts = timestampStr {
                        if let d = iso.date(from: ts) { return d }
                        for df in dateFormatters { if let d = df.date(from: ts) { return d } }
                    }
                    return Date()
                }()

                // Normalize type
                let normalizedType: String? = {
                    guard let t = type?.trimmingCharacters(in: .whitespacesAndNewlines), !t.isEmpty else { return nil }
                    if t.lowercased().hasPrefix("in") { return "Income" }
                    if t.lowercased().hasPrefix("out") { return "Outcome" }
                    return t
                }()
                
                // Check for duplicates
                let finalCurrency = currency ?? Locale.current.currency?.identifier ?? "USD"
                let finalType = normalizedType ?? "Outcome"
                
                let isDuplicate = existingItems.contains { existingItem in
                    return isItemDuplicate(
                        existing: existingItem,
                        newTitle: title,
                        newAmount: amount,
                        newTimestamp: timestamp,
                        newCurrency: finalCurrency,
                        newType: finalType,
                        newCategory: category,
                        criteria: duplicateCriteria
                    )
                }
                
                if isDuplicate {
                    duplicates += 1
                    continue
                }

                // Create Item
                let newItem = Item(context: context)
                newItem.title = title
                newItem.amount = amount
                newItem.currency = finalCurrency
                newItem.type = finalType
                newItem.category = category
                newItem.notes = notes
                newItem.timestamp = timestamp

                imported += 1
            }

            do {
                try context.save()
            } catch {
                thrownError = error
            }
        }

        if let err = thrownError { throw err }
        return (imported: imported, skipped: skipped, duplicates: duplicates)
    }

    // MARK: - Private
    
    // Fetch existing items from Core Data
    private static func fetchExistingItems(context: NSManagedObjectContext) -> [Item] {
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Error fetching existing items: \(error)")
            return []
        }
    }
    
    // Check if an item is a duplicate based on criteria
    private static func isItemDuplicate(existing: Item,
                                        newTitle: String?,
                                        newAmount: NSDecimalNumber?,
                                        newTimestamp: Date,
                                        newCurrency: String,
                                        newType: String,
                                        newCategory: String?,
                                        criteria: DuplicateCriteria) -> Bool {
        var matchCount = 0
        var requiredMatches = 0
        
        // Check amount
        if criteria.checkAmount {
            requiredMatches += 1
            if let existingAmount = existing.amount,
               let newAmt = newAmount,
               existingAmount == newAmt {
                matchCount += 1
            }
        }
        
        // Check timestamp
        if criteria.checkTimestamp {
            requiredMatches += 1
            if let existingTimestamp = existing.timestamp {
                // If timeThreshold is 24 hours or more, compare by date only
                if criteria.timeThreshold >= 86400 {
                    let calendar = Calendar.current
                    let existingDate = calendar.startOfDay(for: existingTimestamp)
                    let newDate = calendar.startOfDay(for: newTimestamp)
                    if existingDate == newDate {
                        matchCount += 1
                    }
                } else {
                    // For smaller thresholds, use time difference
                    let timeDiff = abs(existingTimestamp.timeIntervalSince(newTimestamp))
                    if timeDiff <= criteria.timeThreshold {
                        matchCount += 1
                    }
                }
            }
        }
        
        // Check title
        if criteria.checkTitle {
            requiredMatches += 1
            let existingTitle = existing.title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let newTitleTrimmed = newTitle?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !existingTitle.isEmpty && !newTitleTrimmed.isEmpty && 
               existingTitle.lowercased() == newTitleTrimmed.lowercased() {
                matchCount += 1
            }
        }
        
        // Check type
        if criteria.checkType {
            requiredMatches += 1
            if existing.type == newType {
                matchCount += 1
            }
        }
        
        // Check category
        if criteria.checkCategory {
            requiredMatches += 1
            let existingCategory = existing.category?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let newCategoryTrimmed = newCategory?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if existingCategory.lowercased() == newCategoryTrimmed.lowercased() {
                matchCount += 1
            }
        }
        
        // Check currency
        if criteria.checkCurrency {
            requiredMatches += 1
            if existing.currency == newCurrency {
                matchCount += 1
            }
        }
        
        // Consider it a duplicate if at least 2 criteria match (or all if less than 2 are being checked)
        let threshold = min(2, requiredMatches)
        return requiredMatches > 0 && matchCount >= threshold
    }
    
    // Create missing categories based on imported data
    private static func createMissingCategories(_ categoryTypePairs: Set<CategoryTypePair>, context: NSManagedObjectContext) {
        // Fetch existing categories
        let fetchRequest: NSFetchRequest<Category> = Category.fetchRequest()
        
        do {
            let existingCategories = try context.fetch(fetchRequest)
            let existingPairs = Set(existingCategories.map { 
                CategoryTypePair(name: $0.name ?? "", type: $0.type ?? "")
            })
            
            // Find categories that need to be created
            let missingPairs = categoryTypePairs.subtracting(existingPairs)
            
            // Create missing categories
            for pair in missingPairs {
                let newCategory = Category(context: context)
                newCategory.name = pair.name
                newCategory.type = pair.type
            }
        } catch {
            // If we can't fetch existing categories, we'll just skip category creation
            // The import will still work, but categories won't be automatically created
            print("Error fetching existing categories: \(error)")
        }
    }

    private static func matchesHeader(_ header: [String]) -> Bool {
        let lower = header.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
        return lower == Columns.header
    }

    private static func emptyToNil(_ s: String) -> String? {
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }

    // Escape field for CSV (wrap in quotes if needed, escape quotes by doubling)
    private static func csvEscape(_ field: String) -> String {
        var needsQuoting = false
        for ch in field { if ch == "," || ch == "\n" || ch == "\r" || ch == "\"" { needsQuoting = true; break } }
        if !needsQuoting { return field }
        let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"" + escaped + "\""
    }

    // Basic CSV row parser handling quotes and escaped quotes
    private static func parseCSVRow(_ line: String) -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false
        var i = line.startIndex
        while i < line.endIndex {
            let ch = line[i]
            if inQuotes {
                if ch == "\"" {
                    let next = line.index(after: i)
                    if next < line.endIndex && line[next] == "\"" { // Escaped quote
                        current.append("\"")
                        i = next
                    } else {
                        inQuotes = false
                    }
                } else {
                    current.append(ch)
                }
            } else {
                if ch == "," {
                    result.append(current)
                    current = ""
                } else if ch == "\"" {
                    inQuotes = true
                } else {
                    current.append(ch)
                }
            }
            i = line.index(after: i)
        }
        result.append(current)
        return result
    }
}
