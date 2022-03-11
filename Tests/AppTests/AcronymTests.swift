//
//  File.swift
//
//
//  Created by Civilgistics_Labs on 2/6/22.
//

@testable import App
import XCTVapor

final class AcronymTests: XCTestCase {
    
    let owner = "Owner"
    let item = "Item"
    
    let short = "Alice"
    let long = "alicea"
    let acronymURI = "/api/acronyms/"
    let getAcronymIDURi = "/api/acronyms/id/"
    let searchURI = "/api/acronyms/search/"
    let pageURI = "/api/acronyms/page"
    var app: Application!
    
    override func setUpWithError() throws {
        app = try Application.testable()
    }
    
    override func tearDownWithError() throws {
        app.shutdown()
    }
    
    func testAcronymsCanBeRetrievedFromAPI() async throws {
        
        let crate = try await Crate.create(owner: owner,
                                           item: item,
                                           on: app.db)
        let acronym = try await Acronym.create(short: short,
                                               long: long,
                                               crate: crate,
                                               on: app.db)
        guard let acronymID = acronym.id else {
            throw Abort(.notFound)
        }
        try app.test(.GET, "\(getAcronymIDURi)\(acronymID)", afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
            let acronymResponse = try response.content.decode(Acronym.self)
            //            // 9
            XCTAssertEqual(acronymResponse.short, short)
            XCTAssertEqual(acronymResponse.long, long)
            XCTAssertEqual(acronymResponse.id, acronym.id)
            XCTAssertEqual(acronymResponse.$crate.id, crate.id)
        })
    }
    
    func testAcronymCanBeSavedWithAPI() async throws {
        // 1
        let crate = try await Crate.create(owner: owner,
                                           item: item,
                                           on: app.db)
        let acronym = Acronym(short: short,
                              long: long,
                              crateID: crate.id!)
        
        // 2
        try app.test(.POST, acronymURI, beforeRequest: { req in
            // 3
            try req.content.encode(acronym)
        }, afterResponse: { response in
            // 4
            let receivedAcronym = try response.content.decode(Acronym.self)
            // 5
            XCTAssertEqual(receivedAcronym.short, short)
            XCTAssertEqual(receivedAcronym.long, long)
            XCTAssertNotNil(receivedAcronym.id)
            
            // 6
            try app.test(.GET, acronymURI,
                         afterResponse: { secondResponse in
                // 7
                let acronyms =
                try secondResponse.content.decode([Acronym].self)
                XCTAssertEqual(acronyms.count, 1)
                XCTAssertEqual(acronyms[0].short, short)
                XCTAssertEqual(acronyms[0].long, long)
                XCTAssertEqual(acronyms[0].id, receivedAcronym.id)
            })
        })
    }
    
    func testUpdateCrateForAPI() async throws {
        let updatedShort = "Alice"
        let updatedLong = "alicea"
        
        let crate = try await Crate.create(owner: owner,
                                           item: item,
                                           on: app.db)
        let acronym = try await Acronym.create(short: short,
                                               long: long,
                                               crate: crate,
                                               on: app.db)
        
        guard let id = acronym.id?.uuidString else {
            throw Abort(.notFound)
        }
        let updatedCrateData = CreateAcronymData(short: updatedShort,
                                                 long: updatedLong,
                                                 crateID: crate.id!)
        
        try app.test(.PUT, "\(getAcronymIDURi)\(id)", beforeRequest: { request in
            try request.content.encode(updatedCrateData)
        })
        
        try app.test(.GET, "\(getAcronymIDURi)\(id)", afterResponse: { response in
            let returnedAcronym = try response.content.decode(Acronym.self)
            XCTAssertEqual(returnedAcronym.short, updatedShort)
            XCTAssertEqual(returnedAcronym.long, updatedLong)
        })
    }
    
    func testGettingASingleAcronymFromTheAPI() async throws {
        
        let crate = try await Crate.create(owner: owner,
                                           item: item,
                                           on: app.db)
        let acronym = try await Acronym.create(short: short,
                                               long: long,
                                               crate: crate,
                                               on: app.db)
        
        try app.test(.GET, "\(getAcronymIDURi)\(acronym.id!)",
                     afterResponse: { response in
            print(response.body.string)
            let receivedAcronym = try response.content.decode(Acronym.self)
            // 3
            XCTAssertEqual(receivedAcronym.short, short)
            XCTAssertEqual(receivedAcronym.long, long)
            XCTAssertEqual(receivedAcronym.id, acronym.id)
        })
    }
    
    func testDeleteASingleAcronymFromTheAPI() async throws {
        
        let crate = try await Crate.create(owner: owner,
                                           item: item,
                                           on: app.db)
        let acronym = try await Acronym.create(short: short,
                                               long: long,
                                               crate: crate,
                                               on: app.db)
        
        try app.test(.DELETE, "\(getAcronymIDURi)\(acronym.id!)",
                     afterResponse: { response in
            let receivedCrate = response.status
            XCTAssertEqual(receivedCrate, .ok)
        })
    }
    
    func testGetSearchForCrateAPI() async throws {
        
        let shortTwo = "OMG"
        let longTwo = "Oh My God"
        
        let searchTearm = "Oh"
        
        let crate = try await Crate.create(owner: owner,
                                           item: item,
                                           on: app.db)
        
        async let acronymOne = Acronym.create(short: short,
                                              long: long,
                                              crate: crate,
                                              on: app.db)
        
        async let acronymTwo = Acronym.create(short: shortTwo,
                                              long: longTwo,
                                              crate: crate,
                                              on: app.db)
        let acronymArray = try await [acronymOne,
                                      acronymTwo]
        try app.test(.GET, "\(searchURI)\(searchTearm)",
                     afterResponse: { response in
            print(response.body)
            let acronym = try response.content.decode([Acronym].self)
            XCTAssertEqual(acronym.count, 1)
            XCTAssertEqual(acronym[0].long, acronymArray[1].long)
            //            XCTAssertEqual(crate[0].long, searchTearm)
        })
    }
    
    func testPageAPI() async throws {
        
        let ownerTwo = "OMG"
        let itemTwo = "Oh My God"
        
        let crate = try await Crate.create(owner: owner,
                                           item: item,
                                           on: app.db)
        
        let acronymOne = try await Acronym.create(short: short,
                                                  long: long,
                                                  crate: crate,
                                                  on: app.db)
        
        let acronymTwo = try await Acronym.create(short: ownerTwo,
                                                  long: itemTwo,
                                                  crate: crate,
                                                  on: app.db)
        
        let acronymThree = try await Acronym.create(short: "ownerTwo",
                                                    long: "itemTwo",
                                                    crate: crate,
                                                    on: app.db)
        
        let acronymArray = [acronymOne,
                            acronymTwo,
                            acronymThree]
        try app.test(.GET, "\(pageURI)",
                     afterResponse: { response in
            print(response.body.string)
            let acronym = try response.content.decode(PagedAcronym.self)
            XCTAssertEqual(acronym.items.count, 3)
            XCTAssertEqual(acronym.items[0].id, acronymArray[0].id)
            //            XCTAssertEqual(crate[0].long, searchTearm)
        })
    }
    
    func testAcronymsCategories() async throws {
        let crate = try await Crate.create(owner: owner,
                                           item: item,
                                           on: app.db)
        
        async let categoriesOne = Categories.create(on: app.db)
        async let categoriesTwo = Categories.create(name: "Funny", on: app.db)
        let createCategories = try await [categoriesOne,
                                categoriesTwo]
        let acronym = try await Acronym.create(short: short,
                                               long: long,
                                               crate: crate,
                                               on: app.db)
        try app.test(.POST, "\(getAcronymIDURi)\(acronym.id!)/categories/\(createCategories[0].id!)", afterResponse: { response in
            let receivedCrate = response.status
            XCTAssertEqual(receivedCrate, .ok)
        })
        
        try app.test(.POST, "\(getAcronymIDURi)\(acronym.id!)/categories/\(createCategories[1].id!)", afterResponse: { response in
            dump(response)
            let receivedCrate = response.status
            XCTAssertEqual(receivedCrate, .ok)
        })
        
        try app.test(.GET, "\(getAcronymIDURi)\(acronym.id!)/categories", afterResponse: { response in
            dump(response)
            let categoriesArray = try response.content.decode([App.Categories].self)
            XCTAssertEqual(categoriesArray.count, 2)
            XCTAssertEqual(categoriesArray[0].id, createCategories[0].id)
            XCTAssertEqual(categoriesArray[0].name, createCategories[0].name)
            XCTAssertEqual(categoriesArray[1].id, createCategories[1].id)
            XCTAssertEqual(categoriesArray[1].name, createCategories[1].name)
        })
        
        try app.test(.DELETE, "\(getAcronymIDURi)\(acronym.id!)/categories/\(createCategories[0].id!)")
        
        try app.test(.GET, "\(getAcronymIDURi)\(acronym.id!)/categories", afterResponse: { response in
            let newCategories = try response.content.decode([App.Categories].self)
            XCTAssertEqual(newCategories.count, 1)
        })
    }
}

