#if canImport(SwiftUI) && canImport(ObjectiveC)
import XCTest
import SnapshotTestingPlugin
@testable import SnapshotTesting
import FileSerializationPlugin

class InMemoryFileSerializationPlugin: FileSerializationPlugin {
  static var location: FileSerializationLocation = .plugins("inMemory")
  var inMemory: [String: Data] = [:]
  
  func write(_ data: Data, to url: URL, options: Data.WritingOptions) async throws {
    inMemory[url.absoluteString] = data
  }
  
  func read(_ url: URL) async throws -> Data? {
    return inMemory[url.absoluteString]
  }
  
  // MARK: - SnapshotTestingPlugin
  static var identifier: String = "FileSerializationPlugin.InMemoryFileSerializationPlugin.mock"
  required init() {}
}

class FileSerializerTests: XCTestCase {
  
  var fileSerializer: FileSerializer!
  let testData = "Test Data".data(using: .utf8)!
  let testURL = URL(string: "file:///test.txt")!
  
  override func setUp() {
    super.setUp()
    PluginRegistry.reset() // Reset state before each test
    
    // Register the mock plugin in the PluginRegistry
    PluginRegistry.registerPlugin(InMemoryFileSerializationPlugin() as SnapshotTestingPlugin)
    
    fileSerializer = FileSerializer()
  }
  
  override func tearDown() {
    fileSerializer = nil
    PluginRegistry.reset() // Reset state after each test
    super.tearDown()
  }
  
  func testReadAndWriteUsingMockPlugin() async throws {
    try fileSerializer.write(
      testData,
      to: testURL,
      location: InMemoryFileSerializationPlugin.location
    )
    
    let storedData = try fileSerializer.read(testURL, location: InMemoryFileSerializationPlugin.location)
    XCTAssertNotNil(storedData, "Data should be stored in the in-memory plugin.")
    XCTAssertEqual(storedData, testData, "Stored data should match the test data.")
  }

  func testReadAndWriteDefaultPlugin() async throws {
    let tmpURL = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    try fileSerializer.write(
      testData,
      to: tmpURL
    )
    
    let storedData = try fileSerializer.read(tmpURL)
    XCTAssertNotNil(storedData, "Data should be stored in the in-memory plugin.")
    XCTAssertEqual(storedData, testData, "Stored data should match the test data.")
  }

  func testReadNonExistantFileUsingMockPlugin() async throws {
    let data = try fileSerializer.read(URL(string: "https://www.pointfree.co")!, location: InMemoryFileSerializationPlugin.location)
    XCTAssertNil(data, "This should be empty.")
  }
  
  func testPluginRegistryShouldContainRegisteredPlugins() {
    let plugins = PluginRegistry.allPlugins() as [FileSerialization]
    
    XCTAssertEqual(plugins.count, 1, "There should be one registered plugin.")
    XCTAssertEqual(type(of: plugins[0]).location.rawValue, "inMemory", "The plugin should support the 'inMemory' location.")
  }
}

#endif
