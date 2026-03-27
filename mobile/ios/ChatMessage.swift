import Foundation

struct ChatMessage: Identifiable, Equatable {
    enum Role {
        case system
        case user
        case assistant
    }

    let id = UUID()
    let role: Role
    var content: String
}
