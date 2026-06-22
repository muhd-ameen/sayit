import Foundation

struct RefinedReply: Identifiable, Sendable {
    let id = UUID()
    let label: String
    let text: String
}
