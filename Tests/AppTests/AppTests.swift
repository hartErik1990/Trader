/// Copyright (c) 2021 Razeware LLC
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

@testable import App
import XCTVapor


final class CrateTests: XCTestCase {
    
    let owner = "Alice"
    let item = "alicea"
    let crateURI = "/api/crates/"
    let searchURI = "/api/crates/search/"
    let pageURI = "/api/crates/page"
    let getCrateIDURi = "/api/crates/id/"
    let acronymURI = "/acronyms"
    var app: Application!
    
    override func setUpWithError() throws {
        do {
            app = try Application.testable()
        } catch {
            app.logger.critical("\(error)")
        }
    }
    
    override func tearDownWithError() throws {
        app.shutdown()
    }
    
    func testCratesCanBeRetrievedFromAPI() async throws {
        
        let crate = try await Crate.create(owner: owner,
                                           item: item,
                                           on: app.db)
        
        try app.test(.GET, crateURI, afterResponse: { response in
          //  XCTAssertEqual(response.status, .ok)
            let crates = try response.content.decode([Crate].self)
            
            // 9
            XCTAssertEqual(crates.count, 1)
            XCTAssertEqual(crates[0].owner, owner)
            XCTAssertEqual(crates[0].item, item)
            XCTAssertEqual(crates[0].id, crate.id)
        })
        
    }
    
    func testUpdateCrateForAPI() async throws {
        
        let crate = try await Crate.create(owner: owner,
                                           item: item,
                                           on: app.db)
        
       // let newLong = "Oh My Gosh"
        guard let id = crate.id?.uuidString else {
            throw Abort(.notFound)
        }
        let updatedCrateData = CreateData(owner: owner,
                                            item: item,
                                            id: id)
        
        try app.test(.PUT, "\(crateURI)\(id)", beforeRequest: { request in
          try request.content.encode(updatedCrateData)
        })
        
        try app.test(.GET, "\(getCrateIDURi)\(id)", afterResponse: { response in
          let returnedCrate = try response.content.decode(Crate.self)
          XCTAssertEqual(returnedCrate.owner, owner)
          XCTAssertEqual(returnedCrate.item, item)
        })
    }
    
    func testCrateCanBeSavedWithAPI() throws {
        // 1
        
        let crate = Crate(owner: owner,
                          item: item)
        
        // 2
        try app.test(.POST, crateURI, beforeRequest: { req in
            // 3
            try req.content.encode(crate)
        }, afterResponse: { response in
            // 4
            let receivedCrate = try response.content.decode(Crate.self)
            // 5
            XCTAssertEqual(receivedCrate.owner, owner)
            XCTAssertEqual(receivedCrate.item, item)
            XCTAssertNotNil(receivedCrate.id)
            
            // 6
            try app.test(.GET, crateURI,
                         afterResponse: { secondResponse in
                // 7
                let crates =
                try secondResponse.content.decode([Crate].self)
                XCTAssertEqual(crates.count, 1)
                XCTAssertEqual(crates[0].owner, owner)
                XCTAssertEqual(crates[0].item, item)
                XCTAssertEqual(crates[0].id, receivedCrate.id)
            })
        })
    }
    
    func testGettingASingleCrateFromTheAPI() async throws {
        
        let crate = try await Crate.create(owner: owner,
                                           item: item,
                                           on: app.db)
        
        try app.test(.GET, "\(getCrateIDURi)\(crate.id!)",
                     afterResponse: { response in
            print(response.body.string)
            let receivedCrate = try response.content.decode(Crate.self)
            // 3
            XCTAssertEqual(receivedCrate.owner, owner)
            XCTAssertEqual(receivedCrate.item, item)
            XCTAssertEqual(receivedCrate.id, crate.id)
        })
    }
    
    func testDeleteASingleCrateFromTheAPI() async throws {
        
        let crate = Crate(owner: owner,
                          item: item)
        try await crate.save(on: app.db)
        
        try app.test(.DELETE, "\(getCrateIDURi)\(crate.id!)",
                     afterResponse: { response in
            let receivedCrate = response.status
            XCTAssertEqual(receivedCrate, .ok)
        })
    }
    
    func testGetAcronymsForCrateAPI() async throws {
        
        let acronymShort = "OMG"
        let acronymLong = "Oh My God"
        
        let crate = try await Crate.create(owner: owner,
                                           item: item,
                                           on: app.db)
        
        let awaitAcronym1 = try await Acronym.create(short: acronymShort,
                                                     long: acronymLong,
                                                     crate: crate, on: app.db)
        let _ = try await Acronym.create(short: "LOL", long: "Laugh Out Loud", crate: crate, on: app.db)
        //let awaitAcronyms = try await [awaitAcronym1, awaitAcronym2]
        try app.test(.GET, "\(getCrateIDURi)\(crate.id!)\(acronymURI)",
                     afterResponse: { response in
            print(response.body.string)
            let acronyms = try response.content.decode([Acronym].self)
            XCTAssertEqual(acronyms.count, 2)
            XCTAssertEqual(acronyms[0].id, awaitAcronym1.id)
            XCTAssertEqual(acronyms[0].short, acronymShort)
            XCTAssertEqual(acronyms[0].long, acronymLong)
        })
    }
    
    func testGetSearchForCrateAPI() async throws {
        
        let ownerTwo = "OMG"
        let itemTwo = "Oh My God"
        
        let searchTearm = "Oh"
        
        async let crateOne = Crate.create(owner: owner,
                                           item: item,
                                           on: app.db)
        async let crateTwo = Crate.create(owner: ownerTwo,
                                           item: itemTwo,
                                           on: app.db)
        let crateArray = try await [crateOne,
                                    crateTwo]
        try app.test(.GET, "\(searchURI)\(searchTearm)",
                     afterResponse: { response in
            print(response.body)
            let crate = try response.content.decode([Crate].self)
            XCTAssertEqual(crate.count, 1)
            XCTAssertEqual(crate[0].item, crateArray[1].item)
        })
    }
    
    func testGetAllCratesForDecendingAPI() async throws {
        
        let ownerTwo = "OMG"
        let itemTwo = "Oh My God"
        
        let crateOne = try await Crate.create(owner: owner,
                                           item: item,
                                           on: app.db)
        let crateTwo = try await Crate.create(owner: ownerTwo,
                                           item: itemTwo,
                                           on: app.db)
        let crateArray = [crateOne,
                          crateTwo]
        try app.test(.GET, "\(crateURI)",
                     afterResponse: { response in
            print(response.body)
            let crate = try response.content.decode([Crate].self)
            XCTAssertEqual(crate.count, 2)
            XCTAssertEqual(crate[0].id, crateArray[0].id)
            XCTAssertEqual(crate[1].id, crateArray[1].id)
        })
    }
    
    func testPageAPI() async throws {
        
        let ownerTwo = "OMG"
        let itemTwo = "Oh My God"
        
        let crateOne = try await Crate.create(owner: owner,
                                           item: item,
                                           on: app.db)
        let crateTwo = try await Crate.create(owner: ownerTwo,
                                           item: itemTwo,
                                           on: app.db)
        let crateThree = try await Crate.create(owner: "ownerTwo",
                                           item: "itemTwo",
                                           on: app.db)
        let crateArray = [crateOne,
                          crateTwo,
                          crateThree]
        try app.test(.GET, "\(pageURI)",
                     afterResponse: { response in
            print(response.body.string)
            let crate = try response.content.decode(PagedCrate.self)
            XCTAssertEqual(crate.items.count, 3)
            XCTAssertEqual(crate.items[0].id, crateArray[0].id)
        })
    }
}

