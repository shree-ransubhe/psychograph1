import MessageUI
import SwiftUI

/// Presents a mail compose sheet with optional To, subject, body, and file attachment.
/// Use when you want to pre-fill the user's email and attach a backup file.
struct MailComposeView: UIViewControllerRepresentable {
    let toRecipients: [String]
    let subject: String
    let body: String
    let attachmentURL: URL?
    let onDismiss: () -> Void

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        if !toRecipients.isEmpty {
            vc.setToRecipients(toRecipients)
        }
        vc.setSubject(subject)
        vc.setMessageBody(body, isHTML: false)
        if let url = attachmentURL,
           let data = try? Data(contentsOf: url) {
            vc.addAttachmentData(data, mimeType: "application/json", fileName: url.lastPathComponent)
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onDismiss: onDismiss)
    }

    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let onDismiss: () -> Void

        init(onDismiss: @escaping () -> Void) {
            self.onDismiss = onDismiss
        }

        func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            controller.dismiss(animated: true)
            onDismiss()
        }
    }
}
