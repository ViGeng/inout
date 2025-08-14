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
            "CNY": 7.25, // 1 USD = 7.25 CNY
            "TRY": 32.5, // 1 USD = 32.5 TRY
            "USD": 1.0
        ],
        "EUR": [
            "USD": 1.08, // 1 EUR = 1.08 USD
            "GBP": 0.86, // 1 EUR = 0.86 GBP
            "CNY": 7.87, // 1 EUR = 7.87 CNY
            "TRY": 35.3, // 1 EUR = 35.3 TRY
            "EUR": 1.0
        ],
        "GBP": [
            "USD": 1.27, // 1 GBP = 1.27 USD
            "EUR": 1.16, // 1 GBP = 1.16 EUR
            "CNY": 9.15, // 1 GBP = 9.15 CNY
            "TRY": 41.0, // 1 GBP = 41.0 TRY
            "GBP": 1.0
        ],
        "CNY": [
            "USD": 0.14, // 1 CNY = 0.14 USD
            "EUR": 0.13, // 1 CNY = 0.13 EUR
            "GBP": 0.11, // 1 CNY = 0.11 GBP
            "TRY": 4.48, // 1 CNY = 4.48 TRY
            "CNY": 1.0
        ],
        "TRY": [
            "USD": 0.031, // 1 TRY = 0.031 USD
            "EUR": 0.028, // 1 TRY = 0.028 EUR
            "GBP": 0.024, // 1 TRY = 0.024 GBP
            "CNY": 0.22, // 1 TRY = 0.22 CNY
            "TRY": 1.0
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
