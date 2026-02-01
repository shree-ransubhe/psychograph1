import UIKit

/// Generates a PDF report in A4 Landscape. Up to 2 months per page (each month on half page width).
/// Above each month: AKSK, Email, Mobile, Kendra. Below grid: space for office notes.
final class PDFReportService {

    /// A4 Landscape: width 842, height 595 (points, 72 dpi)
    private static let a4LandscapeWidth: CGFloat = 842
    private static let a4LandscapeHeight: CGFloat = 595
    /// Half page width for one month block
    private static let halfPageWidth: CGFloat = a4LandscapeWidth / 2

    private let storage = StorageService.shared
    private let calendar = Calendar.current

    // Layout constants (logical units; we scale to fit half page)
    private let leftColumnWidth: CGFloat = 56
    private let cellSize: CGFloat = 20
    private let dotSize: CGFloat = 12
    private let rowHeight: CGFloat = 22
    private let dayHeaderHeight: CGFloat = 24
    private let sectionHeaderHeight: CGFloat = 28
    private let edgeMargin: CGFloat = 10
    private let referenceHeaderHeight: CGFloat = 44  // AKSK, email, mobile, Kendra
    private let officeNotesHeight: CGFloat = 60     // Space for office notes

    private var sections: [(category: PsychoCategory, rows: [(subIndex: Int, label: String)])] {
        PsychoCategory.allCases.map { category in
            let rows = category.subcategoryLabels.enumerated()
                .filter { !$0.element.isEmpty }
                .map { (subIndex: $0.offset, label: $0.element) }
            return (category: category, rows: rows)
        }
    }

    /// Generate PDF data for the given months. A4 pages are always in Landscape. Pairs of months side-by-side.
    func generatePDF(months: [(year: Int, month: Int)]) -> Data? {
        guard !months.isEmpty else { return nil }

        let format = UIGraphicsPDFRendererFormat()
        let pageRect = CGRect(x: 0, y: 0, width: Self.a4LandscapeWidth, height: Self.a4LandscapeHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        return renderer.pdfData { context in
            var monthIndex = 0
            while monthIndex < months.count {
                context.beginPage()
                let first = months[monthIndex]
                drawMonth(year: first.year, month: first.month, in: context, at: CGRect(x: 0, y: 0, width: Self.halfPageWidth, height: Self.a4LandscapeHeight))

                if monthIndex + 1 < months.count {
                    let second = months[monthIndex + 1]
                    drawMonth(year: second.year, month: second.month, in: context, at: CGRect(x: Self.halfPageWidth, y: 0, width: Self.halfPageWidth, height: Self.a4LandscapeHeight))
                }
                monthIndex += 2
            }
        }
    }

    /// Draw one month's block: reference header (AKSK, email, mobile, Kendra), month title + benevolence, grid, office notes space.
    private func drawMonth(year: Int, month: Int, in context: UIGraphicsPDFRendererContext, at rect: CGRect) {
        let store = storage.loadStore()
        let daysInMonth: Int
        if let range = calendar.range(of: .day, in: .month, for: dateFor(year: year, month: month)) {
            daysInMonth = range.count
        } else {
            daysInMonth = 31
        }

        let contentWidth = leftColumnWidth + CGFloat(daysInMonth) * cellSize
        let totalRowHeight = sections.reduce(0) { acc, section in
            acc + sectionHeaderHeight + CGFloat(section.rows.count) * rowHeight
        }
        let gridContentHeight = dayHeaderHeight + totalRowHeight
        let availableForGrid = rect.height - 2 * edgeMargin - referenceHeaderHeight - 28 - officeNotesHeight  // 28 = title + benevolence
        let scale = min(
            (rect.width - 2 * edgeMargin) / contentWidth,
            max(0.1, availableForGrid / gridContentHeight)
        )

        let insetRect = rect.insetBy(dx: edgeMargin, dy: edgeMargin)
        var y = insetRect.minY

        // Reference block above month (AKSK, Email, Mobile, Kendra)
        let smallAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8, weight: .regular),
            .foregroundColor: UIColor.darkGray
        ]
        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8, weight: .semibold),
            .foregroundColor: UIColor.darkGray
        ]
        if !storage.profileAKSK.isEmpty {
            ("AKSK: " as NSString).draw(at: CGPoint(x: insetRect.minX, y: y), withAttributes: labelAttrs)
            (storage.profileAKSK as NSString).draw(at: CGPoint(x: insetRect.minX + 28, y: y), withAttributes: smallAttrs)
            y += 10
        }
        if !storage.profileEmail.isEmpty {
            ("Email: " as NSString).draw(at: CGPoint(x: insetRect.minX, y: y), withAttributes: labelAttrs)
            (storage.profileEmail as NSString).draw(at: CGPoint(x: insetRect.minX + 32, y: y), withAttributes: smallAttrs)
            y += 10
        }
        if !storage.profileMobile.isEmpty {
            ("Mobile: " as NSString).draw(at: CGPoint(x: insetRect.minX, y: y), withAttributes: labelAttrs)
            (storage.profileMobile as NSString).draw(at: CGPoint(x: insetRect.minX + 36, y: y), withAttributes: smallAttrs)
            y += 10
        }
        if !storage.profileKendra.isEmpty {
            ("Kendra: " as NSString).draw(at: CGPoint(x: insetRect.minX, y: y), withAttributes: labelAttrs)
            (storage.profileKendra as NSString).draw(at: CGPoint(x: insetRect.minX + 38, y: y), withAttributes: smallAttrs)
            y += 12
        }
        if storage.profileAKSK.isEmpty && storage.profileEmail.isEmpty && storage.profileMobile.isEmpty && storage.profileKendra.isEmpty {
            y += 4
        }

        // Month title and Social Benevolence (श्रमानंद तास)
        let title = monthYearTitle(year: year, month: month)
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold),
            .foregroundColor: UIColor.darkGray
        ]
        (title as NSString).draw(at: CGPoint(x: insetRect.minX, y: y), withAttributes: titleAttrs)
        let benevolence = storage.getMonthBenevolenceForReport(year: year, month: month)
        let subTitle = String(format: "श्रमानंद तास: %.1f hrs", benevolence)
        (subTitle as NSString).draw(at: CGPoint(x: insetRect.minX, y: y + 12), withAttributes: [.font: UIFont.systemFont(ofSize: 9, weight: .regular), .foregroundColor: UIColor.gray])
        let contentStartY = y + 28

        let gridHeight = gridContentHeight * scale
        let gridEndY = contentStartY + gridHeight

        context.cgContext.saveGState()
        context.cgContext.translateBy(x: insetRect.minX, y: contentStartY)
        context.cgContext.scaleBy(x: scale, y: scale)
        let drawOrigin = CGPoint.zero

        // Day header row
        let dayHeaderAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8, weight: .medium),
            .foregroundColor: UIColor.gray
        ]
        ("दिनांक →" as NSString).draw(at: CGPoint(x: drawOrigin.x, y: drawOrigin.y), withAttributes: dayHeaderAttrs)
        for day in 1...daysInMonth {
            let x = leftColumnWidth + CGFloat(day - 1) * cellSize
            ("\(day)" as NSString).draw(at: CGPoint(x: x, y: drawOrigin.y), withAttributes: dayHeaderAttrs)
        }
        var drawY = drawOrigin.y + dayHeaderHeight

        for section in sections {
            UIColor(red: 0.94, green: 0.94, blue: 0.95, alpha: 1).setFill()
            context.cgContext.fill(CGRect(x: drawOrigin.x, y: drawY, width: contentWidth, height: sectionHeaderHeight))
            let sectionAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 9, weight: .bold),
                .foregroundColor: UIColor.darkGray
            ]
            (section.category.displayName as NSString).draw(at: CGPoint(x: drawOrigin.x + 2, y: drawY + 6), withAttributes: sectionAttrs)
            drawY += sectionHeaderHeight

            for row in section.rows {
                let label = "\(row.subIndex + 1)) \(row.label)"
                let rowLabelAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 8, weight: .regular),
                    .foregroundColor: UIColor.darkGray
                ]
                (label as NSString).draw(at: CGPoint(x: drawOrigin.x + 2, y: drawY + 4), withAttributes: rowLabelAttrs)

                for day in 1...daysInMonth {
                    let dateKey = String(format: "%04d-%02d-%02d", year, month, day)
                    let isFilled = store.get(dateKey: dateKey, categoryId: section.category.rawValue, subcategoryIndex: row.subIndex) == 1
                    let cellX = leftColumnWidth + CGFloat(day - 1) * cellSize
                    let dotX = cellX + (cellSize - dotSize) / 2
                    let dotY = drawY + (rowHeight - dotSize) / 2
                    let dotRect = CGRect(x: dotX, y: dotY, width: dotSize, height: dotSize)
                    if isFilled {
                        UIColor(red: 0.32, green: 0.52, blue: 0.52, alpha: 1).setFill()
                        context.cgContext.fillEllipse(in: dotRect)
                    } else {
                        context.cgContext.setStrokeColor(UIColor(red: 0.88, green: 0.88, blue: 0.9, alpha: 1).cgColor)
                        context.cgContext.setLineWidth(1)
                        context.cgContext.strokeEllipse(in: dotRect)
                    }
                }
                drawY += rowHeight
            }
        }

        context.cgContext.restoreGState()

        // Office notes area (below grid, within half page)
        let notesY = gridEndY + 8
        let notesRect = CGRect(x: insetRect.minX, y: notesY, width: insetRect.width, height: officeNotesHeight - 8)
        context.cgContext.setStrokeColor(UIColor.lightGray.cgColor)
        context.cgContext.setLineWidth(0.5)
        context.cgContext.stroke(notesRect)
        ("Office notes:" as NSString).draw(at: CGPoint(x: notesRect.minX + 2, y: notesRect.minY + 2), withAttributes: [.font: UIFont.systemFont(ofSize: 7, weight: .regular), .foregroundColor: UIColor.gray])
    }

    private func dateFor(year: Int, month: Int) -> Date {
        var c = DateComponents()
        c.year = year
        c.month = month
        c.day = 1
        return calendar.date(from: c) ?? Date()
    }

    private func monthYearTitle(year: Int, month: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: dateFor(year: year, month: month))
    }
}
