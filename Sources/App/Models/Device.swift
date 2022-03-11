/// Copyright (c) 2020 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.
//hi
import Fluent
import Vapor

final class Device: Model, Content {
  static let schema = "devices"

  typealias System = Shared.Device.System

  @ID(key: .id)
  var id: UUID?

  @Field(key: "system")
  var system: System

  @Field(key: "os_version")
  var osVersion: String

  @Field(key: "push_token")
  var pushToken: String?

  @Field(key: "channels")
  var channels: String

  init() {}

  init(id: UUID? = nil, system: System, osVersion: String, pushToken: String?, channels: [String]? ) {
    self.id = id
    self.system = system
    self.osVersion = osVersion
    self.pushToken = pushToken
    self.channels = channels?.toChannelsString() ?? ""
  }
}

extension Device {
  class func pushTokens(for channels: [String], on db: Database) async throws -> [String] {
    return try await Device.query(on: db)
      .filter(\.$pushToken != nil)
      .group(.or) { builder in
        channels.forEach { builder.filter(\.$channels ~~ $0) }
    }
    .all(\Device.$pushToken)
    .compactMap { $0 }

  }
}

extension Array where Element == String {
  func toChannelsString() -> String {
    compactMap { $0.isEmpty ? nil : $0 }
      .map { $0.appending("\n") }
      .joined()
  }
}

extension Shared.Device: Content {}

extension Device {
  func toPublic() throws -> Shared.Device {
    .init(id: try requireID(),
          system: system,
          osVersion: osVersion,
          pushToken: pushToken,
          channels: channels.isEmpty ? [] : channels.components(separatedBy: "\n"))
  }
}
