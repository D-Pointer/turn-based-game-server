import Vapor

/// Called after your application has initialized.
public func boot(_ app: Application) throws {
    // your code here
    if !FileManager.default.fileExists(atPath: "data") {
        try FileManager.default.createDirectory(atPath: "data", withIntermediateDirectories: true, attributes: nil)
    }
}
