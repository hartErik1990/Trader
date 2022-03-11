//
//  File.swift
//
//
//  Created by Civilgistics_Labs on 2/6/22.
//

@testable import App
import XCTVapor

final class CategoriesTests: XCTestCase {
    
    let owner = "Owner"
    let item = "Item"
    
    let short = "Alice"
    let long = "alicea"
    
    let categoriesName = "Alicia"
    
    let categoriesURI = "/api/categories/"
    let categories = "/categories/"
    let acronyms = "/acronyms/"
    let acronymURI = "/api/acronyms/"
    
    let getCategoriesIDURi = "/api/categories/id/"
    let searchURI = "/api/categories/search/"
    let pageURI = "/api/categories/page"
    
    var app: Application!
    
    override func setUpWithError() throws {
        app = try Application.testable()
    }
    
    override func tearDownWithError() throws {
        app.shutdown()
    }
    
    func testAcronymCanBeSavedWithAPI() async throws {
        // 1
        let categories = Categories(name: short)
        // 2
        try app.test(.POST, categoriesURI, beforeRequest: { req in
            // 3
            try req.content.encode(categories)
        }, afterResponse: { response in
            // 4
            let receivedCategories = try response.content.decode(Categories.self)
            // 5
            XCTAssertEqual(receivedCategories.name, short)
            XCTAssertNotNil(receivedCategories.id)
    
        })
    }
    
    func testCategoriessCanBeRetrievedFromAPI() async throws {
   
        let categories = try await Categories.create(name: short,
                        on: app.db)
        guard let categoriesID = categories.id else {
            throw Abort(.notFound)
        }
        try app.test(.GET, "\(getCategoriesIDURi)\(categoriesID)", afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
            let categoriesResponse = try response.content.decode(Categories.self)
//            // 9
            XCTAssertEqual(categoriesResponse.name, short)
            XCTAssertEqual(categoriesResponse.id, categories.id)
        })
        
    }
    
    func testCategoriesCanBeSavedWithAPI() async throws {
        // 1
        let categories = Categories(name: short)
        // 2
        try app.test(.POST, categoriesURI, beforeRequest: { req in
            // 3
            try req.content.encode(categories)
        }, afterResponse: { response in
            // 4
            let receivedCategories = try response.content.decode(Categories.self)
            // 5
            XCTAssertEqual(receivedCategories.name, short)
            XCTAssertNotNil(receivedCategories.id)
            
            guard let id = receivedCategories.id else {
                throw Abort(.notFound)
            }
            try app.test(.GET, "\(getCategoriesIDURi)\(id)", afterResponse: { response in
                XCTAssertEqual(response.status, .ok)
                let categoriesResponse = try response.content.decode(Categories.self)
                //            // 9
                XCTAssertEqual(categoriesResponse.name, short)
                XCTAssertEqual(categoriesResponse.id, categories.id)
            })
        })
        // 2
    }
    
    func testUpdateCrateForAPI() async throws {
        let updatedShort = "OMG"

        let categories = try await Categories.create(name: short,
                                                     on: app.db)
        
        // let newLong = "Oh My Gosh"
        guard let id = categories.id?.uuidString else {
            throw Abort(.notFound)
        }
        let updatedCrateData = CreateCategoriesData(name: updatedShort)
        
        try app.test(.PUT, "\(getCategoriesIDURi)\(id)", beforeRequest: { request in
            try request.content.encode(updatedCrateData)
        }, afterResponse: { response in
            try app.test(.GET, "\(getCategoriesIDURi)\(id)", afterResponse: { response in
                let returnedCategories = try response.content.decode(Categories.self)
                XCTAssertEqual(returnedCategories.name, updatedShort)
            })
        })
    }
    
    func testGettingASingleCategoriesFromTheAPI() async throws {

        let categories = try await  Categories.create(name: short,
                        on: app.db)
        try app.test(.GET, "\(getCategoriesIDURi)\(categories.id!)",
                     afterResponse: { response in
            print(response.body.string)
            let receivedCategories = try response.content.decode(Categories.self)
            // 3
            XCTAssertEqual(receivedCategories.name, short)
            XCTAssertEqual(receivedCategories.id, categories.id)
        })
    }
    
    func testDeleteASingleCategoriesFromTheAPI() async throws {

        let categories = try await Categories.create(name: short,
                        on: app.db)
        
        try app.test(.DELETE, "\(getCategoriesIDURi)\(categories.id!)",
                     afterResponse: { response in
            let receivedCrate = response.status
            XCTAssertEqual(receivedCrate, .ok)
        })
    }
    
    func testGetSearchForCrateAPI() async throws {
        
        let shortTwo = "OMG"
        
        let searchTearm = "Oh"
 
        async let categoriesOne = Categories.create(name: short,
                        on: app.db)
        
        async let categoriesTwo = Categories.create(name: shortTwo,
                        on: app.db)
        let categoriesArray = try await [categoriesOne,
                                       categoriesTwo]
        try app.test(.GET, "\(searchURI)\(searchTearm)",
                     afterResponse: { response in
            let categoriesArr = try response.content.decode([Categories].self)
            XCTAssertEqual(categoriesArr.count, 1)
            XCTAssertEqual(categoriesArr[0].name, categoriesArray[1].name)
        })
    }
    
    func testPageAPI() async throws {

        let categoriesOne = try await Categories.create(name: short,
                        on: app.db)
        
        let categoriesTwo = try await Categories.create(name: short,
                        on: app.db)
    
        let categoriesThree = try await Categories.create(name: short,
                        on: app.db)

        let categoriesArray = [categoriesOne,
                            categoriesTwo,
                            categoriesThree]
        try app.test(.GET, "\(pageURI)",
                     afterResponse: { response in
            print(response.body.string)
            let categories = try response.content.decode(PagedCategories.self)
            XCTAssertEqual(categories.items.count, 3)
            XCTAssertEqual(categories.items[0].id, categoriesArray[0].id)
        })
    }
    
    func testGettingACategoriesAcronymsFromTheAPI() async throws {
        let acronymShort = "OMG"
        let acronymLong = "Oh My God"
        let acronym = try await Acronym.create(short: acronymShort, long: acronymLong, on: app.db)
        let acronymTwo = try await Acronym.create(short: short, long: long, on: app.db)
        let categoriesOne = try await Categories.create(name: categoriesName, on: app.db)
        
        try app.test(.POST, "\(getCategoriesIDURi)\(categoriesOne.id!)\(acronyms)\(acronym.id!)")
        try app.test(.POST, "\(getCategoriesIDURi)\(categoriesOne.id!)\(acronyms)\(acronymTwo.id!)")
        
        try app.test(.GET, "\(getCategoriesIDURi)\(categoriesOne.id!)\(acronyms)", afterResponse: { response in
            let acronyms = try response.content.decode([Acronym].self)
            XCTAssertEqual(acronyms.count, 2)
            XCTAssertEqual(acronyms[0].id, acronym.id)
            XCTAssertEqual(acronyms[0].short, acronymShort)
            XCTAssertEqual(acronyms[0].long, acronymLong)
        })
        
        try app.test(.DELETE, "\(getCategoriesIDURi)\(categoriesOne.id!)\(acronyms)\(acronym.id!)")
        
        try app.test(.GET, "\(getCategoriesIDURi)\(categoriesOne.id!)\(acronyms)", afterResponse: { response in
            let newCategories = try response.content.decode([App.Acronym].self)
            XCTAssertEqual(newCategories.count, 1)
        })
    }
}

