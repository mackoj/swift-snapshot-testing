import SnapshotTestingPlugin
import Foundation

public typealias FileSerializationPlugin = FileSerialization & SnapshotTestingPlugin

public protocol FileSerialization {
  static var location: FileSerializationLocation { get }
  func write(_ data: Data, to url: URL, options: Data.WritingOptions) async throws
  func read(_ url: URL) async throws -> Data?
}

public enum FileSerializationLocation: RawRepresentable, Sendable, Equatable {
  
  public static let defaultValue: FileSerializationLocation = .local
  
  case local
  
  case plugins(String)
  
  public init?(rawValue: String) {
    self = rawValue == "local" ? .local : .plugins(rawValue)
  }
  
  public var rawValue: String {
    switch self {
    case .local: return "local"
    case let .plugins(value): return value
    }
  }
}
