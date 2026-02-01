import SwiftUI

// MARK: - Scroll offset for horizontal sync of frozen day row (landscape) and category row (portrait)
private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct GraphView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var selectedYear: Int
    @State private var selectedMonth: Int
    @State private var store: CheckInStore = CheckInStore()
    @State private var horizontalScrollOffset: CGFloat = 0
    @State private var showAddTodaysGraphSheet = false
    @State private var showExportReportSheet = false
    @State private var showPortraitToast = false

    private let calendar = Calendar.current
    private var isPortrait: Bool { horizontalSizeClass == .compact }

    init() {
        let now = Date()
        _selectedYear = State(initialValue: Calendar.current.component(.year, from: now))
        _selectedMonth = State(initialValue: Calendar.current.component(.month, from: now))
    }

    private var daysInSelectedMonth: Int {
        guard let range = calendar.range(of: .day, in: .month, for: dateForFirstOfMonth) else { return 31 }
        return range.count
    }

    private var dateForFirstOfMonth: Date {
        var comps = DateComponents()
        comps.year = selectedYear
        comps.month = selectedMonth
        comps.day = 1
        return calendar.date(from: comps) ?? Date()
    }

    private var socialBenevolenceTotal: Double {
        StorageService.shared.getMonthTotalSocialBenevolence(year: selectedYear, month: selectedMonth)
    }

    private let yearRange = 10
    private var yearChoices: [Int] {
        let currentYear = calendar.component(.year, from: Date())
        return (currentYear - yearRange...currentYear).reversed()
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                // Month / Year picker with chevrons for one-step back/forth
                HStack(spacing: AppTheme.spacingM) {
                    Picker("Year", selection: $selectedYear) {
                        ForEach(yearChoices, id: \.self) { year in
                            Text(String(year)).tag(year)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(minWidth: 56)
                    .onChange(of: selectedYear) { _, _ in
                        refreshStore()
                    }

                    Picker("Month", selection: $selectedMonth) {
                        ForEach(1...12, id: \.self) { month in
                            Text(monthNameShort(month)).tag(month)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(minWidth: 44)
                    .onChange(of: selectedMonth) { _, _ in
                        refreshStore()
                    }

                    Spacer(minLength: 0)

                    // Chevrons: previous / next month
                    HStack(spacing: AppTheme.spacingL) {
                        Button {
                            goToPreviousMonth()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(AppTheme.textPrimary)
                        }
                        Button {
                            goToNextMonth()
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(AppTheme.textPrimary)
                        }
                    }
                }
                .padding(.horizontal, AppTheme.spacingM)
                .padding(.vertical, AppTheme.spacingS)

                Text("Social Benevolence (month total): \(formatHours(socialBenevolenceTotal)) hrs")
                    .font(AppTheme.caption())
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.horizontal, AppTheme.spacingM)
                    .padding(.bottom, AppTheme.spacingS)

                // Report grid in horizontal (wider) orientation for easier reference
                graphContentWithHorizontalOrientation
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(uiColor: .systemBackground))
            .overlay(alignment: .top) {
                if showPortraitToast {
                    portraitRotateToast(onDismiss: { showPortraitToast = false })
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .opacity.combined(with: .move(edge: .top))
                        ))
                        .zIndex(1)
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showPortraitToast)
            .navigationTitle("Report")
            .navigationBarTitleDisplayMode(isPortrait ? .inline : .automatic)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("+ Add") {
                        showAddTodaysGraphSheet = true
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.primary)
                }
                ToolbarItem(placement: .secondaryAction) {
                    Button {
                        showExportReportSheet = true
                    } label: {
                        Label("Export Report", systemImage: "square.and.arrow.up")
                    }
                    .foregroundStyle(AppTheme.primary)
                }
            }
            .sheet(isPresented: $showAddTodaysGraphSheet) {
                AddTodaysGraphView(
                    initialDate: Date(),
                    onDismiss: { showAddTodaysGraphSheet = false },
                    onCompleteAndGoToReport: {
                        showAddTodaysGraphSheet = false
                        refreshStore()
                    }
                )
            }
            .sheet(isPresented: $showExportReportSheet) {
                ExportReportView(
                    initialFromYear: selectedYear,
                    initialFromMonth: selectedMonth,
                    initialToYear: selectedYear,
                    initialToMonth: selectedMonth
                )
            }
            .onAppear {
                refreshStore()
                if isPortrait { showPortraitToast = true }
            }
            .onReceive(NotificationCenter.default.publisher(for: .psychographReportDataDidClear)) { _ in
                refreshStore()
            }
        }
    }

    /// Toast shown in portrait only: "For better experience just rotate phone to landscape mode." Dismissed only when user taps close.
    private func portraitRotateToast(onDismiss: @escaping () -> Void) -> some View {
        HStack(spacing: AppTheme.spacingS) {
            Image(systemName: "rotate.right")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(AppTheme.primary)
            Text("For better experience just rotate phone to landscape mode.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color(uiColor: .label))
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color(uiColor: .tertiaryLabel))
            }
        }
        .padding(.horizontal, AppTheme.spacingM)
        .padding(.vertical, AppTheme.spacingS)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadiusSmall))
        .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 2)
        .padding(.horizontal, AppTheme.spacingM)
        .padding(.top, AppTheme.spacingS)
    }

    private func goToPreviousMonth() {
        if selectedMonth == 1 {
            selectedMonth = 12
            selectedYear = max(selectedYear - 1, calendar.component(.year, from: Date()) - yearRange)
        } else {
            selectedMonth -= 1
        }
        refreshStore()
    }

    private func goToNextMonth() {
        if selectedMonth == 12 {
            selectedMonth = 1
            selectedYear = min(selectedYear + 1, calendar.component(.year, from: Date()))
        } else {
            selectedMonth += 1
        }
        refreshStore()
    }

    private func refreshStore() {
        store = StorageService.shared.loadStore()
    }

    /// Total height of the report grid content (day row + all section headers + all data rows + padding).
    private var reportGridContentHeight: CGFloat {
        let header = dayHeaderHeight
        let body = sections.reduce(0) { acc, section in
            acc + sectionHeaderHeight + CGFloat(section.rows.count) * rowHeight
        }
        return header + body + edgePadding * 2
    }

    /// Portrait column: either a grey parent category column or a subcategory column.
    private enum PortraitColumn {
        case parent(PsychoCategory)
        case subcategory(category: PsychoCategory, subIndex: Int, label: String)

        var isParent: Bool {
            if case .parent = self { return true }
            return false
        }
    }

    /// Portrait only: one parent column per section (grey) then subcategory columns. No parent header row.
    private var portraitColumns: [PortraitColumn] {
        var cols: [PortraitColumn] = []
        for section in sections {
            cols.append(.parent(section.category))
            for row in section.rows {
                cols.append(.subcategory(category: section.category, subIndex: row.subIndex, label: "\(row.subIndex + 1)) \(row.label)"))
            }
        }
        return cols
    }

    /// Portrait: day column width, parent column width (grey), and subcategory column width.
    private var portraitDayColWidth: CGFloat { 28 }
    private var portraitParentColWidth: CGFloat { 22 }
    private var portraitSubcategoryColWidth: CGFloat { 24 }
    /// Height of category header row (vertical labels only; parent columns show category name).
    private var portraitCategoryRowHeight: CGFloat { 56 }

    /// Portrait: total width of category columns (parent + subcategory columns).
    private var portraitColumnsTotalWidth: CGFloat {
        portraitColumns.reduce(0) { sum, col in
            sum + (col.isParent ? portraitParentColWidth : portraitSubcategoryColWidth)
        }
    }

    /// Portrait only: swapped layout — days as rows; one grey parent column per section, then subcategory columns. Category row scrolls with content (no sticky).
    private var portraitSwappedGrid: some View {
        let days = daysInSelectedMonth
        let columns = portraitColumns
        let dayColWidth = portraitDayColWidth
        let parentColWidth = portraitParentColWidth
        let subcategoryColWidth = portraitSubcategoryColWidth
        let columnsTotalWidth = portraitColumnsTotalWidth
        let totalContentWidth = dayColWidth + columnsTotalWidth

        return GeometryReader { geo in
            let cardWidth = geo.size.width - 2 * edgePadding
            ScrollView([.horizontal, .vertical], showsIndicators: true) {
                VStack(alignment: .leading, spacing: 0) {
                    // Single category header row: parent columns (grey + category name vertical) + subcategory columns (label vertical)
                    HStack(alignment: .top, spacing: 0) {
                        Color.clear
                            .frame(width: dayColWidth, height: portraitCategoryRowHeight)
                        portraitCategoryHeaderRow(columns: columns, parentColWidth: parentColWidth, subcategoryColWidth: subcategoryColWidth)
                            .frame(width: columnsTotalWidth)
                    }
                    .background(Color(uiColor: .tertiarySystemBackground))

                    // Data rows: day # column + one row per day (grey parent cells + dots)
                    HStack(alignment: .top, spacing: 0) {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(1...days, id: \.self) { day in
                                Text("\(day)")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(AppTheme.textTertiary)
                                    .frame(width: dayColWidth, height: rowHeight, alignment: .center)
                            }
                        }
                        .frame(width: dayColWidth)

                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(1...days, id: \.self) { day in
                                HStack(alignment: .center, spacing: 0) {
                                    ForEach(Array(columns.enumerated()), id: \.offset) { idx, col in
                                        let colWidth = col.isParent ? parentColWidth : subcategoryColWidth
                                        switch col {
                                        case .parent:
                                            Color.clear
                                                .frame(width: colWidth, height: rowHeight)
                                                .background(Color(uiColor: .tertiarySystemBackground))
                                        case .subcategory(let category, let subIndex, _):
                                            let dateKey = dateKey(for: day)
                                            let isFilled = store.get(dateKey: dateKey, categoryId: category.rawValue, subcategoryIndex: subIndex) == 1
                                            Circle()
                                                .fill(isFilled ? AppTheme.filledDot : Color.clear)
                                                .overlay(Circle().stroke(AppTheme.emptyDot, lineWidth: isFilled ? 0 : 1))
                                                .frame(width: dotSize, height: dotSize)
                                                .frame(width: subcategoryColWidth, height: rowHeight, alignment: .center)
                                        }
                                    }
                                }
                                .frame(width: columnsTotalWidth)
                            }
                        }
                        .frame(width: columnsTotalWidth)
                    }
                }
                .padding(edgePadding)
                .frame(width: totalContentWidth, alignment: .leading)
                .frame(minWidth: cardWidth, alignment: .leading)
            }
            .background(Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadiusSmall))
            .shadow(color: AppTheme.cardShadow, radius: 4, x: 0, y: 2)
            .padding(.horizontal, edgePadding)
        }
    }

    /// Single header row: one grey column per parent (category name vertical) + subcategory columns (label vertical). Text laid out in cell-sized frame then rotated so it isn't clipped; explicit primary color on grey.
    private func portraitCategoryHeaderRow(
        columns: [PortraitColumn],
        parentColWidth: CGFloat,
        subcategoryColWidth: CGFloat
    ) -> some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(Array(columns.enumerated()), id: \.offset) { idx, col in
                let colWidth = col.isParent ? parentColWidth : subcategoryColWidth
                switch col {
                case .parent(let category):
                    Text(category.displayName)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .multilineTextAlignment(.leading)
                        .frame(width: colWidth, height: portraitCategoryRowHeight, alignment: .topLeading)
                        .rotationEffect(.degrees(90))
                        .frame(width: colWidth, height: portraitCategoryRowHeight, alignment: .topLeading)
                        .background(Color(uiColor: .tertiarySystemBackground))
                case .subcategory(_, _, let label):
                    Text(label)
                        .font(.system(size: 9, weight: .regular))
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.5)
                        .multilineTextAlignment(.leading)
                        .frame(width: subcategoryColWidth, height: portraitCategoryRowHeight, alignment: .topLeading)
                        .rotationEffect(.degrees(90))
                        .frame(width: subcategoryColWidth, height: portraitCategoryRowHeight, alignment: .topLeading)
                        .background(Color(uiColor: .secondarySystemBackground))
                }
            }
        }
    }

    /// Portrait: Figma layout — categories as horizontal columns (top), dates as rows, date column fixed on RIGHT. Landscape: unchanged (dates as columns, categories on left).
    private var graphContentWithHorizontalOrientation: some View {
        GeometryReader { geo in
            let isPortraitOrientation = geo.size.height > geo.size.width
            if isPortraitOrientation {
                portraitGridFigmaStyle
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            } else {
                reportGridWithFrozenHeaders
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Portrait only (Figma): [Scrollable: category headers row + grid (rows=days, cols=subcategories)] | [Fixed right: दिनांक → and day numbers column].
    private var portraitGridFigmaStyle: some View {
        let days = daysInSelectedMonth
        let columns = portraitColumns
        let parentColWidth = portraitParentColWidth
        let subcategoryColWidth = portraitSubcategoryColWidth
        let columnsTotalWidth = portraitColumnsTotalWidth
        let dateColWidth: CGFloat = 28

        return HStack(alignment: .top, spacing: 0) {
            // Left: scrollable category headers + data grid (rows = days, columns = subcategories)
            ScrollView([.horizontal, .vertical], showsIndicators: true) {
                VStack(alignment: .leading, spacing: 0) {
                    portraitCategoryHeaderRow(columns: columns, parentColWidth: parentColWidth, subcategoryColWidth: subcategoryColWidth)
                        .frame(width: columnsTotalWidth)
                    ForEach(1...days, id: \.self) { day in
                        portraitDataRow(day: day, columns: columns, parentColWidth: parentColWidth, subcategoryColWidth: subcategoryColWidth)
                            .frame(width: columnsTotalWidth)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .background(Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadiusSmall))
            .shadow(color: AppTheme.cardShadow, radius: 4, x: 0, y: 2)

            // Right: fixed date column (दिनांक → and 1..days) — does not change x position
            portraitDateColumnRight(days: days, dateColWidth: dateColWidth)
        }
        .padding(.horizontal, 0)
    }

    /// Fixed date column on the right: "दिनांक →" then day numbers vertically.
    private func portraitDateColumnRight(days: Int, dateColWidth: CGFloat) -> some View {
        VStack(alignment: .center, spacing: 0) {
            Text("दिनांक →")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(width: dateColWidth, height: portraitCategoryRowHeight, alignment: .center)
            ForEach(1...days, id: \.self) { day in
                Text("\(day)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(AppTheme.textTertiary)
                    .frame(width: dateColWidth, height: rowHeight, alignment: .center)
            }
        }
        .frame(width: dateColWidth)
        .background(Color(uiColor: .tertiarySystemBackground))
    }

    /// One data row for a given day: grey parent cells + dot cells per subcategory.
    private func portraitDataRow(day: Int, columns: [PortraitColumn], parentColWidth: CGFloat, subcategoryColWidth: CGFloat) -> some View {
        HStack(alignment: .center, spacing: 0) {
            ForEach(Array(columns.enumerated()), id: \.offset) { _, col in
                let colWidth = col.isParent ? parentColWidth : subcategoryColWidth
                switch col {
                case .parent:
                    Color.clear
                        .frame(width: colWidth, height: rowHeight)
                        .background(Color(uiColor: .tertiarySystemBackground))
                case .subcategory(let category, let subIndex, _):
                    let dateKey = dateKey(for: day)
                    let isFilled = store.get(dateKey: dateKey, categoryId: category.rawValue, subcategoryIndex: subIndex) == 1
                    Circle()
                        .fill(isFilled ? AppTheme.filledDot : Color.clear)
                        .overlay(Circle().stroke(AppTheme.emptyDot, lineWidth: isFilled ? 0 : 1))
                        .frame(width: dotSize, height: dotSize)
                        .frame(width: subcategoryColWidth, height: rowHeight, alignment: .center)
                        .background(Color(uiColor: .secondarySystemBackground))
                }
            }
        }
        .frame(height: rowHeight)
    }

    /// Sections: one per main category (भय, राग, धैर्य, शांति) with its subcategory rows.
    private var sections: [(category: PsychoCategory, rows: [(subIndex: Int, label: String)])] {
        PsychoCategory.allCases.map { category in
            let rows = category.subcategoryLabels.enumerated()
                .filter { !$0.element.isEmpty }
                .map { (subIndex: $0.offset, label: $0.element) }
            return (category: category, rows: rows)
        }
    }

    private var reportGridWithFrozenHeaders: some View {
        let days = daysInSelectedMonth
        let gridContentWidth = CGFloat(days) * cellSize

        return GeometryReader { geo in
            // Portrait: use 100% available width (no horizontal padding). Landscape: use card width with padding.
            let horizontalPadding: CGFloat = isPortrait ? 0 : edgePadding
            let cardWidth = geo.size.width - 2 * horizontalPadding
            let scrollContentWidth: CGFloat? = isPortrait ? cardWidth : nil

            ZStack(alignment: .topLeading) {
                // Scrollable body: left column (section headers + subcategory rows) + grid (section header rows + dot rows). Day row is NOT in scroll — it stays fixed via overlay.
                ScrollView(.vertical, showsIndicators: true) {
                    HStack(alignment: .top, spacing: 0) {
                        leftColumnBody()
                            .frame(width: leftColumnWidth, alignment: .leading)
                            .fixedSize(horizontal: true, vertical: false)

                        ScrollView(.horizontal, showsIndicators: true) {
                            gridBody(days: days)
                                .frame(width: gridContentWidth)
                                .background(
                                    GeometryReader { innerGeo in
                                        Color.clear.preference(
                                            key: ScrollOffsetPreferenceKey.self,
                                            value: innerGeo.frame(in: .named("hScroll")).minX
                                        )
                                    }
                                )
                        }
                        .frame(maxWidth: .infinity)
                        .coordinateSpace(name: "hScroll")
                    }
                    .padding(horizontalPadding)
                    .frame(maxWidth: scrollContentWidth, alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(uiColor: .secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadiusSmall))
                .shadow(color: AppTheme.cardShadow, radius: 4, x: 0, y: 2)
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { horizontalScrollOffset = $0 }

                // Frozen day row (and corner): always visible at top. Date column (day numbers) on right keeps fixed x position per Figma — no horizontal offset.
                frozenDayRowOverlay(days: days)
            }
            .padding(.horizontal, horizontalPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Tighter padding so first column and row stay visible on small portrait screens.
    private var edgePadding: CGFloat { AppTheme.spacingS }

    /// Left column body (landscape): section headers (bold, grey) + subcategory rows, horizontal labels. No corner — corner is in overlay.
    private func leftColumnBody() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(sections.enumerated()), id: \.offset) { _, section in
                // Section header: category name in bold, grey row
                Text(section.category.displayName)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .frame(width: leftColumnWidth, height: sectionHeaderHeight, alignment: .leading)
                    .padding(.leading, 2)
                    .background(Color(uiColor: .tertiarySystemBackground))

                ForEach(Array(section.rows.enumerated()), id: \.offset) { _, row in
                    Text("\(row.subIndex + 1)) \(row.label)")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(width: leftColumnWidth, height: rowHeight, alignment: .leading)
                }
            }
        }
    }

    /// Grid body (landscape): section header rows (grey) + dot rows. No day row — day row is in overlay.
    private func gridBody(days: Int) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(sections.enumerated()), id: \.offset) { _, section in
                // Section header row: grey background, no dots
                Color.clear
                    .frame(width: CGFloat(days) * cellSize, height: sectionHeaderHeight)
                    .background(Color(uiColor: .tertiarySystemBackground))

                ForEach(Array(section.rows.enumerated()), id: \.offset) { _, row in
                    HStack(spacing: 0) {
                        ForEach(1...days, id: \.self) { day in
                            let dateKey = dateKey(for: day)
                            let isFilled = store.get(dateKey: dateKey, categoryId: section.category.rawValue, subcategoryIndex: row.subIndex) == 1
                            Circle()
                                .fill(isFilled ? AppTheme.filledDot : Color.clear)
                                .overlay(
                                    Circle()
                                        .stroke(AppTheme.emptyDot, lineWidth: isFilled ? 0 : 1)
                                )
                                .frame(width: dotSize, height: dotSize)
                                .frame(width: cellSize, height: rowHeight, alignment: .center)
                        }
                    }
                    .frame(height: rowHeight)
                }
            }
        }
    }

    private func dayHeaderRow(days: Int) -> some View {
        HStack(spacing: 0) {
            ForEach(1...days, id: \.self) { day in
                Text("\(day)")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(AppTheme.textTertiary)
                    .frame(width: cellSize, height: dayHeaderHeight, alignment: .center)
            }
        }
        .frame(height: dayHeaderHeight)
    }

    /// Frozen day row (and corner): always visible at top. Date column (day numbers) at right keeps fixed x position — does not scroll horizontally (per Figma).
    private func frozenDayRowOverlay(days: Int) -> some View {
        HStack(alignment: .top, spacing: 0) {
            Text("दिनांक →")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(width: leftColumnWidth, height: dayHeaderHeight, alignment: .leading)
            // Date column: fixed x position (no horizontal scroll offset)
            dayHeaderRow(days: days)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: dayHeaderHeight)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, isPortrait ? 0 : edgePadding)
        .background(Color(uiColor: .secondarySystemBackground))
        .shadow(color: AppTheme.cardShadow, radius: 2, x: 0, y: 1)
    }

    /// Narrow left column so it stays visible in portrait on small screens (e.g. 320pt width).
    private var leftColumnWidth: CGFloat { 56 }
    private var cellSize: CGFloat { 20 }
    private var dotSize: CGFloat { 12 }
    private var rowHeight: CGFloat { 22 }
    private var dayHeaderHeight: CGFloat { 24 }
    private var sectionHeaderHeight: CGFloat { 28 }

    private func dateKey(for day: Int) -> String {
        String(format: "%04d-%02d-%02d", selectedYear, selectedMonth, day)
    }

    /// MMM format (e.g. Jan, Feb) for month selector CTA.
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

    private func formatHours(_ hours: Double) -> String {
        if hours == Double(Int(hours)) {
            return "\(Int(hours))"
        }
        return String(format: "%.1f", hours)
    }
}
