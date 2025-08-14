//
//  SubscriptionManager.swift
//  inout
//
//  Created by wei on 2025/8/14.
//

import Foundation
import CoreData

class SubscriptionManager {
    static let shared = SubscriptionManager()
    private let persistenceController = PersistenceController.shared

    func generateTransactions() {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<Subscription> = Subscription.fetchRequest()

        do {
            let subscriptions = try context.fetch(fetchRequest)
            for subscription in subscriptions {
                generateTransactions(for: subscription, in: context)
            }
            try context.save()
        } catch {
            // Handle fetch error
            print("Error fetching subscriptions: \(error)")
        }
    }

    private func generateTransactions(for subscription: Subscription, in context: NSManagedObjectContext) {
        guard let startDate = subscription.startDate,
              let cycleUnit = subscription.cycleUnit,
              let cycleCount = subscription.cycleCount as? Int,
              let title = subscription.title,
              let amount = subscription.amount,
              let type = subscription.type,
              let category = subscription.category
        else { return }

        var nextDate = subscription.lastGeneratedDate ?? startDate
        let now = Date()

        while shouldGenerate(nextDate: nextDate, subscription: subscription, now: now) {
            let newItem = Item(context: context)
            newItem.timestamp = nextDate
            newItem.title = title
            newItem.amount = amount
            newItem.currency = subscription.currency
            newItem.type = type
            newItem.category = category
            newItem.notes = subscription.notes

            subscription.lastGeneratedDate = nextDate
            nextDate = calculateNextDate(from: nextDate, cycleUnit: cycleUnit, cycleCount: cycleCount) ?? now
        }
    }

    private func shouldGenerate(nextDate: Date, subscription: Subscription, now: Date) -> Bool {
        if let endDate = subscription.endDate, nextDate > endDate {
            return false
        }
        return nextDate <= now
    }

    private func calculateNextDate(from date: Date, cycleUnit: String, cycleCount: Int) -> Date? {
        var dateComponent = DateComponents()
        switch cycleUnit {
        case "Day":
            dateComponent.day = cycleCount
        case "Week":
            dateComponent.weekOfYear = cycleCount
        case "Month":
            dateComponent.month = cycleCount
        case "Year":
            dateComponent.year = cycleCount
        default:
            return nil
        }
        return Calendar.current.date(byAdding: dateComponent, to: date)
    }
}
