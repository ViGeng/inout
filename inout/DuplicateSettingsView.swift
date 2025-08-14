import SwiftUI

enum TimeComparisonMode {
    case date
    case timeRange
}

struct DuplicateSettingsView: View {
    @Binding var criteria: CSVManager.DuplicateCriteria
    @Environment(\.presentationMode) var presentationMode
    
    @State private var checkAmount: Bool
    @State private var checkTimestamp: Bool
    @State private var checkTitle: Bool
    @State private var checkType: Bool
    @State private var checkCategory: Bool
    @State private var checkCurrency: Bool
    @State private var timeThresholdMinutes: Double
    @State private var timeComparisonMode: TimeComparisonMode
    
    init(criteria: Binding<CSVManager.DuplicateCriteria>) {
        self._criteria = criteria
        let currentCriteria = criteria.wrappedValue
        self._checkAmount = State(initialValue: currentCriteria.checkAmount)
        self._checkTimestamp = State(initialValue: currentCriteria.checkTimestamp)
        self._checkTitle = State(initialValue: currentCriteria.checkTitle)
        self._checkType = State(initialValue: currentCriteria.checkType)
        self._checkCategory = State(initialValue: currentCriteria.checkCategory)
        self._checkCurrency = State(initialValue: currentCriteria.checkCurrency)
        self._timeThresholdMinutes = State(initialValue: min(currentCriteria.timeThreshold / 60.0, 60))
        self._timeComparisonMode = State(initialValue: currentCriteria.timeThreshold >= 86400 ? .date : .timeRange)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Duplicate Detection Criteria")) {
                    Text("Select at least 2 criteria to identify duplicate transactions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Toggle("Amount", isOn: $checkAmount)
                    Toggle("Title", isOn: $checkTitle)
                    Toggle("Date/Time", isOn: $checkTimestamp)
                    
                    if checkTimestamp {
                        VStack(alignment: .leading) {
                            Picker("Compare by", selection: $timeComparisonMode) {
                                Text("Same Date").tag(TimeComparisonMode.date)
                                Text("Time Range").tag(TimeComparisonMode.timeRange)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding(.bottom, 4)
                            
                            if timeComparisonMode == .timeRange {
                                Text("Time threshold: \(Int(timeThresholdMinutes)) minute(s)")
                                    .font(.caption)
                                Slider(value: $timeThresholdMinutes, in: 1...60, step: 1)
                                Text("Transactions within this time range will be considered as having the same timestamp")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Transactions on the same date will be considered as having the same timestamp")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.leading)
                    }
                    
                    Toggle("Type (Income/Outcome)", isOn: $checkType)
                    Toggle("Category", isOn: $checkCategory)
                    Toggle("Currency", isOn: $checkCurrency)
                }
                
                Section(header: Text("How it works")) {
                    Text("When importing CSV files, transactions will be considered duplicates if they match on at least 2 of the selected criteria above.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Default: Amount + Date + Type. This helps avoid importing the same transaction multiple times from different exports.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Example: A $50 \"Outcome\" transaction on 2025-08-14 will be considered a duplicate of another $50 \"Outcome\" on the same date, regardless of the time or title.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Import Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveCriteria()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(selectedCriteriaCount < 1)
                }
            }
        }
    }
    
    private var selectedCriteriaCount: Int {
        [checkAmount, checkTimestamp, checkTitle, checkType, checkCategory, checkCurrency]
            .filter { $0 }
            .count
    }
    
    private func saveCriteria() {
        let threshold = timeComparisonMode == .date ? 86400.0 : timeThresholdMinutes * 60.0
        criteria = CSVManager.DuplicateCriteria(
            checkAmount: checkAmount,
            checkTimestamp: checkTimestamp,
            checkTitle: checkTitle,
            checkType: checkType,
            checkCategory: checkCategory,
            checkCurrency: checkCurrency,
            timeThreshold: threshold
        )
    }
}

struct DuplicateSettingsView_Previews: PreviewProvider {
    @State static var criteria = CSVManager.DuplicateCriteria.default
    
    static var previews: some View {
        DuplicateSettingsView(criteria: $criteria)
    }
}
