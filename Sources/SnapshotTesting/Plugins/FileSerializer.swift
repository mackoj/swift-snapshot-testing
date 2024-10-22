#if canImport(SwiftUI)
import Foundation
import FileSerializationPlugin

final class FileSerializer {
  
  /// A collection of plugins that conform to the `FileSerialization` protocol.
  private let plugins: [any FileSerialization]
  
  init() {
    self.plugins = PluginRegistry.allPlugins()
  }
  
  func write(_ data: Data, to url: URL, options: Data.WritingOptions = [], location: FileSerializationLocation = .defaultValue) throws {
    if let plugin = self.plugins.first(where: { type(of: $0).location == location }) {
      Task {
        try await plugin.write(data, to: url, options: options)
      }
      return
    }
    
    try data.write(to: url)
  }
  
  
  func read(_ url: URL, location: FileSerializationLocation = .defaultValue) throws -> Data? {
    if let plugin = self.plugins.first(where: { type(of: $0).location == location }) {
      let semaphore = DispatchSemaphore(value: 0)
      var result: Result<Data?, Error>?
      
      Task {
        do {
          let data = try await plugin.read(url)
          result = .success(data)
        } catch {
          result = .failure(error)
        }
        semaphore.signal() // Release the semaphore once async task is done
      }
      
      semaphore.wait() // Wait for async task to complete
      
      switch result {
      case .success(let data):
        return data
      case .failure(let error):
        throw error
      case .none:
        fatalError("Unexpected error occurred")
      }
    }
    
    // Synchronous path for fallback
    return try Data(contentsOf: url)
  }
}
#endif
