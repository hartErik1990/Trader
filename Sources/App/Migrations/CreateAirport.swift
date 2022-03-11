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

struct CreateAirport: AsyncMigration {
    func prepare(on database: Database) async throws {
    try await database.schema(Airport.schema)
      .id()
      .field("iata_code", .string, .required)
      .unique(on: "iata_code")
      .field("long_name", .string, .required)
      .create()
      
    
    let initialAirports = [
      Airport(iataCode: "TLV", longName: "Tel Aviv - Ben Gurion"),
      Airport(iataCode: "JFK", longName: "New York - John F. Kennedy"),
      Airport(iataCode: "GRU", longName: "São Paulo - Guarulhos"),
      Airport(iataCode: "CDG", longName: "Paris - Charles de Gaulle"),
    ]
//        let css = try await initialAirports.forEach { airport in
//           try await airport.save(on: database)
//        }
        for airport in initialAirports {
            try await airport.save(on: database)
        }
        return
//        let tha = initialAirports
//            .map { airport in
//                try await airport.save(on: database)
//            }
//
//          .map { $0.save(on: database) }
//          //.flatten(on: database.eventLoop)
//      }
//    return createTable.flatMap {
//      initialAirports
//        .map { $0.save(on: database) }
//        .flatten(on: database.eventLoop)
//    }
  }
  
    func revert(on database: Database) async throws {
   try await database.schema(Airport.schema).delete()
  }
}
