import Foundation

public struct DepoEntry: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var type: DepoType
    public var time: Date

    public init(id: UUID = UUID(), type: DepoType, time: Date) {
        self.id = id
        self.type = type
        self.time = time
    }
}

public enum DepoType: String, Codable, Sendable {
    case `in`, out
}
