import Foundation

/// Main categories A, B, C, D with their subcategory counts: A=11, B=8, C=6, D=3
enum PsychoCategory: String, CaseIterable, Identifiable {
    case A
    case B
    case C
    case D

    var id: String { rawValue }

    /// Display name for section headers (e.g. भय for Category A)
    var displayName: String {
        switch self {
        case .A: return "भय"
        case .B: return "राग"
        case .C: return "धैर्य"
        case .D: return "शांति"
        }
    }

    /// Subcategory labels
    var subcategoryLabels: [String] {
        switch self {
        case .A: return [
            "संकट", "मानभंग", "असत्य", "काम", "गैरसमज",
            "सुस्ती", "अनिश्चय", "रोग", "वेदना", "बाह्यवास्तू", "इतर"
        ]
        case .B: return [
            "पुत्र", "धनहानी", "विरोध", "अयश", "बुद्धी / विस्मरण",
            "अकौतुक", "वेड", "इतर"
        ]
        case .C: return [
            "सत् ईर्षा", "जनमाया", "श्रमानंद", "सुचितानंद", "संकटधैर्य", "इतर"
        ]
        case .D: return ["त्याग", "शांति", ""]
        }
    }

    var subcategoryCount: Int { subcategoryLabels.count }
}
