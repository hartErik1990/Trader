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

import Fluent
import Vapor
import APNS

final class Flight: Model, Content {
  static let schema = "flights"
  
  @ID(key: .id)
  var id: UUID?
  
  @Parent(key: "arrival_airport_id")
  var arrivalAirport: Airport
  
  @Field(key: "flight_number")
  var flightNumber: String
  
  init() { }
  
  init(id: UUID? = nil, arrivalAirportId: Airport.IDValue, flightNumber: String) {
    self.id = id
    self.$arrivalAirport.id = arrivalAirportId
    self.flightNumber = flightNumber
  }
  
  init(id: UUID? = nil, arrivalAirport: Airport, flightNumber: String) throws {
    self.id = id
    self.$arrivalAirport.value = arrivalAirport
    self.$arrivalAirport.id = try arrivalAirport.requireID()
    self.flightNumber = flightNumber
  }
}

extension Flight {
  struct Notification: APNS.APNSwiftNotification {
    let aps: APNSwiftPayload
    let flight: Flight
  }
  
  func createNotification(on db: Database) async throws -> Notification {
   let airport = try await $arrivalAirport.get(reload: true, on: db)
      let flightId = try self.requireID()
      
      let alert = APNSwiftAlert(
        title: "A flight is about to land!",
        subtitle: self.flightNumber,
        body: "Flight \(self.flightNumber) is around \(airport.iataCode). Go get some nice pictures!"
      )
      return Notification(aps: .init(alert: alert,
                                     sound: .normal("Cessna.aiff"),
                                     threadID: flightId.uuidString),
                          flight: self)
//          .flatMapThrowing { airport in
//      let flightId = try self.requireID()
//      let alert = APNSwiftAlert(
//        title: "A flight is about to land!",
//        subtitle: self.flightNumber,
//        body: "Flight \(self.flightNumber) is around \(airport.iataCode). Go get some nice pictures!"
//      )
//
//      return Notification(aps: .init(alert: alert,
//                                     sound: .normal("Cessna.aiff"),
//                                     threadID: flightId.uuidString),
//                          flight: self)
//    }
  }
}
