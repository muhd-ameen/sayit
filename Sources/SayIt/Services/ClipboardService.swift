import AppKit

enum ClipboardService {
    static func get() -> String {
        NSPasteboard.general.string(forType: .string) ?? ""
    }

    static func copy(_ text: String) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
    }
}
