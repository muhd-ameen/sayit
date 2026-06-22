import Foundation
import Observation

struct ToneSlot: Identifiable, Codable, Equatable, Sendable {
    var id: String
    var label: String
    var instruction: String

    static let defaults: [ToneSlot] = [
        ToneSlot(id: "default",      label: "Default",      instruction: "natural, direct voice"),
        ToneSlot(id: "shorter",      label: "Shorter",      instruction: "same message, as few words as possible"),
        ToneSlot(id: "professional", label: "Professional", instruction: "formal register, polished")
    ]
}

@Observable
final class ToneSettings {
    static let shared = ToneSettings()
    private let storageKey = "toneSlots_v1"

    var slots: [ToneSlot] {
        didSet { persist() }
    }

    private init() {
        if let data = UserDefaults.standard.data(forKey: "toneSlots_v1"),
           let decoded = try? JSONDecoder().decode([ToneSlot].self, from: data) {
            self.slots = decoded
        } else {
            self.slots = ToneSlot.defaults
        }
    }

    func resetToDefaults() {
        slots = ToneSlot.defaults
    }

    private func persist() {
        UserDefaults.standard.set(try? JSONEncoder().encode(slots), forKey: storageKey)
    }
}
