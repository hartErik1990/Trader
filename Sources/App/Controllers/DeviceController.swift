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

import Vapor
import APNS

struct DeviceController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    let group = routes.grouped("devices")
    group.put("update", use: put)
    group.post(":id", "test-push", use: sendTestPush)
  }
  
    func put(_ req: Request) async throws -> Response {
        let updateDeviceData = try req.content.decode(Shared.UpdateDevice.self)
        print(updateDeviceData)
        if let deviceId = updateDeviceData.id {
            guard let device = try await Device.find(deviceId, on: req.db) else {
                throw Abort(.notFound)
            }
            device.osVersion = updateDeviceData.osVersion
            device.pushToken = updateDeviceData.pushToken
            device.channels = updateDeviceData.channels?.toChannelsString() ?? ""
            try await device.save(on: req.db)
            do {
                return try await device.toPublic().encodeResponse(status: .ok, for: req)
            } catch {
                throw Abort(.notAcceptable)
            }
        }
        
        let newDevice = Device(system: updateDeviceData.system,
                               osVersion: updateDeviceData.osVersion,
                               pushToken: updateDeviceData.pushToken,
                               channels: updateDeviceData.channels)
        try await newDevice.save(on: req.db)
        do {
            return try await newDevice.toPublic().encodeResponse(status: .ok, for: req)
        } catch {
            throw Abort(.notAcceptable)
        }
    }

    func sendTestPush(_ req: Request) async throws -> HTTPStatus {
        guard let device = try await Device.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound)
        }
        let payload = APNSwiftPayload(alert: .init(title: "Test notification",
                                                   body: "It works!"),
                                      sound: .normal("default"))
        do {
            try await req.apns.send(payload, to: device)
        } catch {
            throw Abort(.badRequest)
        }
        return .ok
    }

}
