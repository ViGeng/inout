import SwiftUI

struct SubscriptionFormView: View {
    @Binding var title: String
    @Binding var amount: String
    @Binding var currency: String
    @Binding var cycleUnit: String
    @Binding var cycleCount: Int
    @Binding var startDate: Date
    @Binding var endDate: Date?
    @Binding var notes: String

    private let units = ["day", "week", "month", "year"]

    var body: some View {
        // Control to manage optional end date without forcing a value
        let hasEndDate = Binding<Bool>(
            get: { endDate != nil },
            set: { newVal in
                if newVal {
                    if endDate == nil { endDate = startDate }
                } else {
                    endDate = nil
                }
            }
        )

        Form {
            Section(header: Text("Details")) {
                #if os(macOS)
                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
                    GridRow {
                        Text("Title").foregroundColor(.gray)
                            .frame(width: 100, alignment: .trailing)
                        TextField("Title", text: $title)
                            .textFieldStyle(.roundedBorder)
                    }
                    GridRow {
                        Text("Amount").foregroundColor(.gray)
                            .frame(width: 100, alignment: .trailing)
                        TextField("Amount", text: $amount)
                            .textFieldStyle(.roundedBorder)
                    }
                    GridRow {
                        Text("Currency").foregroundColor(.gray)
                            .frame(width: 100, alignment: .trailing)
                        Picker("", selection: $currency) {
                            ForEach(Locale.commonISOCurrencyCodes, id: \.self) { Text($0).tag($0) }
                        }
                        .labelsHidden()
                    }
                    GridRow {
                        Text("Cycle").foregroundColor(.gray)
                            .frame(width: 100, alignment: .trailing)
                        HStack {
                            Stepper(value: $cycleCount, in: 1...120) {
                                Text("Every \(cycleCount)")
                            }
                            Picker("", selection: $cycleUnit) {
                                ForEach(units, id: \.self) { Text($0.capitalized).tag($0) }
                            }
                            .labelsHidden()
                            .pickerStyle(.segmented)
                        }
                    }
                    GridRow {
                        Text("From").foregroundColor(.gray)
                            .frame(width: 100, alignment: .trailing)
                        DatePicker("", selection: $startDate, displayedComponents: [.date])
                            .labelsHidden()
                    }
                    GridRow {
                        Text("End").foregroundColor(.gray)
                            .frame(width: 100, alignment: .trailing)
                        Toggle("", isOn: hasEndDate)
                            .labelsHidden()
                    }
                    if hasEndDate.wrappedValue == false {
                        GridRow {
                            Text("")
                                .frame(width: 100, alignment: .trailing)
                            Text("If set, billing will stop after the end date.")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                    if hasEndDate.wrappedValue {
                        GridRow {
                            Text("")
                                .frame(width: 100, alignment: .trailing)
                            DatePicker("", selection: Binding(get: { endDate ?? startDate }, set: { endDate = $0 }), displayedComponents: [.date])
                                .labelsHidden()
                        }
                    }
                    GridRow(alignment: .top) {
                        Text("Notes").foregroundColor(.gray)
                            .frame(width: 100, alignment: .trailing)
                        TextField("Notes", text: $notes)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                #else
                TextField("Title", text: $title)
                TextField("Amount", text: $amount)
                    .keyboardType(.decimalPad)
                Picker("Currency", selection: $currency) {
                    ForEach(Locale.commonISOCurrencyCodes, id: \.self) { Text($0).tag($0) }
                }
                Stepper(value: $cycleCount, in: 1...120) {
                    Text("Every \(cycleCount)")
                }
                Picker("Unit", selection: $cycleUnit) {
                    ForEach(units, id: \.self) { unit in
                        let short: String = {
                            switch unit {
                            case "day": return "Day"
                            case "week": return "Week"
                            case "year": return "Year"
                            default: return "Month"
                            }
                        }()
                        Text(short).tag(unit)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                DatePicker("From", selection: $startDate, displayedComponents: [.date])
                Toggle("Has End Date", isOn: hasEndDate)
                Text("If set, billing will stop after the end date.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                if hasEndDate.wrappedValue {
                    DatePicker("End", selection: Binding(get: { endDate ?? startDate }, set: { endDate = $0 }), displayedComponents: [.date])
                }
                TextField("Notes", text: $notes)
                #endif
            }
        }
        #if os(macOS)
        .formStyle(.grouped)
        #endif
    }
}
