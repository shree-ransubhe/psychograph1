import SwiftUI

/// Month selection and PDF export. Used in Settings (main feature) and from GraphView CTA.
struct ExportReportView: View {
    @Environment(\.dismiss) private var dismiss

    private let calendar = Calendar.current
    private let storage = StorageService.shared
    private let yearRange = 10

    @State private var fromYear: Int
    @State private var fromMonth: Int
    @State private var toYear: Int
    @State private var toMonth: Int
    @State private var isExporting = false
    @State private var exportError: String?
    @State private var showShareSheet = false
    @State private var exportedPDFURL: URL?
    @State private var showBenevolencePrompt = false
    @State private var showBenevolenceEntry = false

    private var yearChoices: [Int] {
        let currentYear = calendar.component(.year, from: Date())
        return (currentYear - yearRange...currentYear).reversed()
    }

    init(initialFromYear: Int? = nil, initialFromMonth: Int? = nil, initialToYear: Int? = nil, initialToMonth: Int? = nil) {
        let now = Date()
        let y = calendar.component(.year, from: now)
        let m = calendar.component(.month, from: now)
        _fromYear = State(initialValue: initialFromYear ?? y)
        _fromMonth = State(initialValue: initialFromMonth ?? max(1, m - 2))
        _toYear = State(initialValue: initialToYear ?? y)
        _toMonth = State(initialValue: initialToMonth ?? m)
    }

    /// Ordered list of (year, month) from From to To (inclusive).
    private var selectedMonths: [(year: Int, month: Int)] {
        var list: [(year: Int, month: Int)] = []
        var y = fromYear
        var m = fromMonth
        let endY = toYear
        let endM = toMonth
        while y < endY || (y == endY && m <= endM) {
            list.append((year: y, month: m))
            if m == 12 {
                m = 1
                y += 1
            } else {
                m += 1
            }
        }
        return list
    }

    private var canExport: Bool {
        !selectedMonths.isEmpty && (fromYear < toYear || (fromYear == toYear && fromMonth <= toMonth))
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Text("From")
                            .frame(width: 44, alignment: .leading)
                        Picker("Year", selection: $fromYear) {
                            ForEach(yearChoices, id: \.self) { Text(String($0)).tag($0) }
                        }
                        .pickerStyle(.menu)
                        .frame(minWidth: 70)
                        Picker("Month", selection: $fromMonth) {
                            ForEach(1...12, id: \.self) { month in
                                Text(monthNameShort(month)).tag(month)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(minWidth: 60)
                    }
                    HStack {
                        Text("To")
                            .frame(width: 44, alignment: .leading)
                        Picker("Year", selection: $toYear) {
                            ForEach(yearChoices, id: \.self) { Text(String($0)).tag($0) }
                        }
                        .pickerStyle(.menu)
                        .frame(minWidth: 70)
                        Picker("Month", selection: $toMonth) {
                            ForEach(1...12, id: \.self) { month in
                                Text(monthNameShort(month)).tag(month)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(minWidth: 60)
                    }
                } header: {
                    Text("Months to include")
                        .font(AppTheme.sectionHeader())
                        .foregroundStyle(AppTheme.textSecondary)
                } footer: {
                    Text("Report will show up to 2 months per A4 page. Select the date range you want to print.")
                        .font(AppTheme.caption())
                        .foregroundStyle(AppTheme.textTertiary)
                }

                if !selectedMonths.isEmpty {
                    Section {
                        Text("\(selectedMonths.count) month\(selectedMonths.count == 1 ? "" : "s") selected")
                            .font(AppTheme.caption())
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }

                if let err = exportError {
                    Section {
                        Text(err)
                            .font(AppTheme.caption())
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    Button {
                        showBenevolencePrompt = true
                    } label: {
                        HStack {
                            if isExporting {
                                ProgressView()
                                    .scaleEffect(0.9)
                            }
                            Text(isExporting ? "Generating…" : "Save PDF Report")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(!canExport || isExporting)
                    .foregroundStyle(canExport && !isExporting ? AppTheme.primary : .gray)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Export Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(AppTheme.primary)
                }
            }
            .alert("Add benevolence hours?", isPresented: $showBenevolencePrompt) {
                Button("Yes") {
                    showBenevolenceEntry = true
                }
                Button("No") {
                    exportPDF()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Do you want to add or update श्रमानंद तास (benevolence hours) for the selected months? You can enter hours per month before generating the PDF.")
            }
            .sheet(isPresented: $showBenevolenceEntry) {
                BenevolenceEntryView(
                    months: selectedMonths,
                    onSaveAndExport: {
                        showBenevolenceEntry = false
                        exportPDF()
                    },
                    onSkipExport: {
                        showBenevolenceEntry = false
                    }
                )
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportedPDFURL {
                    ShareSheet(activityItems: [url])
                }
            }
        }
    }

    private func exportPDF() {
        exportError = nil
        isExporting = true
        let months = selectedMonths
        DispatchQueue.global(qos: .userInitiated).async {
            guard let data = PDFReportService().generatePDF(months: months) else {
                FailureLogger.shared.logFailure(context: "PDF Export", message: "Could not generate PDF.")
                DispatchQueue.main.async {
                    exportError = "Could not generate PDF."
                    isExporting = false
                }
                return
            }
            let fileName = "PsychoGraph_Report_\(fromYear)_\(fromMonth)_to_\(toYear)_\(toMonth).pdf"
            let tempDir = FileManager.default.temporaryDirectory
            let fileURL = tempDir.appendingPathComponent(fileName)
            do {
                try data.write(to: fileURL)
                DispatchQueue.main.async {
                    exportedPDFURL = fileURL
                    showShareSheet = true
                    isExporting = false
                }
            } catch {
                FailureLogger.shared.logError(error, context: "PDF Export (save)")
                DispatchQueue.main.async {
                    exportError = "Could not save PDF."
                    isExporting = false
                }
            }
        }
    }

    private func monthNameShort(_ month: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        var comps = DateComponents()
        comps.month = month
        comps.day = 1
        if let date = calendar.date(from: comps) {
            return formatter.string(from: date)
        }
        return String(month)
    }
}

// MARK: - Benevolence entry (श्रमानंद तास) per selected month before export

struct BenevolenceEntryView: View {
    let months: [(year: Int, month: Int)]
    let onSaveAndExport: () -> Void
    let onSkipExport: () -> Void

    private let calendar = Calendar.current
    private let storage = StorageService.shared

    @State private var hoursByMonth: [String: String] = [:]  // "yyyy-MM" -> "12.5"
    @FocusState private var focusedMonthKey: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Enter श्रमानंद तास (benevolence hours) for each month. Leave blank to keep existing total.")
                        .font(AppTheme.caption())
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Section {
                    ForEach(Array(months.enumerated()), id: \.offset) { _, m in
                        let key = monthKey(year: m.year, month: m.month)
                        let existing = storage.getMonthBenevolenceForReport(year: m.year, month: m.month)
                        HStack {
                            Text(monthYearLabel(year: m.year, month: m.month))
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(AppTheme.textPrimary)
                            Spacer()
                            TextField("hrs", text: Binding(
                                get: { hoursByMonth[key] ?? (existing > 0 ? String(format: "%.1f", existing) : "") },
                                set: { hoursByMonth[key] = $0 }
                            ))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 72)
                            .focused($focusedMonthKey, equals: key)
                        }
                    }
                } header: {
                    Text("श्रमानंद तास (hrs)")
                        .font(AppTheme.sectionHeader())
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Benevolence Hours")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") {
                        onSkipExport()
                    }
                    .foregroundStyle(AppTheme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save & Export PDF") {
                        saveAndExport()
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.primary)
                }
            }
            .onAppear {
                for m in months {
                    let key = monthKey(year: m.year, month: m.month)
                    if hoursByMonth[key] == nil {
                        let v = storage.getMonthBenevolenceForReport(year: m.year, month: m.month)
                        if v > 0 {
                            hoursByMonth[key] = String(format: "%.1f", v)
                        }
                    }
                }
            }
        }
    }

    private func monthKey(year: Int, month: Int) -> String {
        String(format: "%04d-%02d", year, month)
    }

    private func monthYearLabel(year: Int, month: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        var c = DateComponents()
        c.year = year
        c.month = month
        c.day = 1
        if let date = calendar.date(from: c) {
            return formatter.string(from: date)
        }
        return "\(month)/\(year)"
    }

    private func saveAndExport() {
        for m in months {
            let key = monthKey(year: m.year, month: m.month)
            if let text = hoursByMonth[key], !text.isEmpty, let hours = Double(text), hours >= 0 {
                storage.setMonthBenevolenceOverride(year: m.year, month: m.month, hours: hours)
            }
        }
        onSaveAndExport()
    }
}

/// UIKit share sheet wrapper for sharing the PDF file.
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
