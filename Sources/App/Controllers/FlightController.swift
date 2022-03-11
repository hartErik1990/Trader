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
import FluentSQL
import Vapor

private struct NewFlight: Content {
    let flightNumber: String
    let airportIataCode: String
}

struct FlightController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let grouped = routes.grouped("flights")
        grouped.post("new", use: create)
        grouped.get(use: index)
    }
    
    private func index(_ req: Request) throws -> EventLoopFuture<[Flight]> {
        Flight.query(on: req.db)
            .with(\.$arrivalAirport)
            .all()
            .map { $0.reversed() }
    }
    
    private func create(_ req: Request) async throws -> Flight {
        let newFlightData = try req.content.decode(NewFlight.self)
        
        guard let airport = try await Airport.query(on: req.db)
                .filter(\.$iataCode == newFlightData.airportIataCode)
                .first() else {
                    throw Abort(.notFound)
                }
        do {
            let flight = try Flight(arrivalAirport: airport, flightNumber: newFlightData.flightNumber)
            try await flight.save(on: req.db)
            //try await req.eventLoop.execute {
            try await sendNotification(for: flight, db: req.db, apns: req.apns)
            //}
            return flight
        } catch {
            throw Abort(.notFound)
        }
    }
    
    private func sendNotification(for flight: Flight, db: Database, apns: Request.APNS) async throws {
        let notification = try await flight.createNotification(on: db)
        try await apns.send(notification, toChannel: flight.arrivalAirport.iataCode, on: db)
    }
}
