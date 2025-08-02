import Foundation

struct CurrencyConverter {

    static let localCurrencyCode: String = Locale.current.currency?.identifier ?? "USD"

    // Exchange rates relative to the localCurrencyCode
    // You can modify these rates as needed.
    // Example: if localCurrencyCode is "USD", then 1 EUR = 1.08 USD
    static var exchangeRates: [String: [String: Double]] = [
        "USD": [
            "EUR": 0.92, // 1 USD = 0.92 EUR
            "GBP": 0.79, // 1 USD = 0.79 GBP
            "USD": 1.0
        ],
        "EUR": [
            "USD": 1.08, // 1 EUR = 1.08 USD
            "GBP": 0.86, // 1 EUR = 0.86 GBP
            "EUR": 1.0
        ],
        "GBP": [
            "USD": 1.27, // 1 GBP = 1.27 USD
            "EUR": 1.16, // 1 GBP = 1.16 EUR
            "GBP": 1.0
        ]
    ]

    static func convert(_ amount: NSDecimalNumber, from sourceCurrency: String, to targetCurrency: String) -> NSDecimalNumber {
        if sourceCurrency == targetCurrency {
            return amount
        }

        guard let sourceRates = exchangeRates[sourceCurrency], 
              let rate = sourceRates[targetCurrency] else {
            print("Warning: Exchange rate not found for \(sourceCurrency) to \(targetCurrency). Returning original amount.")
            return amount
        }

        return amount.multiplying(by: NSDecimalNumber(value: rate))
    }

    static func convertToLocalCurrency(_ amount: NSDecimalNumber, from sourceCurrency: String) -> NSDecimalNumber {
        return convert(amount, from: sourceCurrency, to: localCurrencyCode)
    }
}