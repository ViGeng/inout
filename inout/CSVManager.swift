import Foundation
import CoreData

// MARK: - CSV Helpers

struct CSVManager {
    struct Columns {
        static let header = ["title", "amount", "currency", "type", "category", "notes", "timestamp"]
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

    // Import Items from CSV string. Returns (imported count, skipped count)
    static func importItemsFromCSV(_ csv: String, into context: NSManagedObjectContext) throws -> (Int, Int) {
        var imported = 0
        var skipped = 0
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

                // Create Item
                let newItem = Item(context: context)
                newItem.title = title
                newItem.amount = amount
                newItem.currency = currency ?? Locale.current.currency?.identifier ?? "USD"
                newItem.type = normalizedType ?? "Outcome"
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
        return (imported, skipped)
    }

    // MARK: - Private

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
