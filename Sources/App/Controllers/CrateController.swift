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

import Fluent
import Vapor

struct CrateController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        
        let crateGroup = routes.grouped("api", "crates")
        
        crateGroup.get(use: all(req:))
        crateGroup.post(use: create(req:))
        crateGroup.post("trade", use: trade(req:))
        crateGroup.put(":id", use: update(req:))

        let singleCrateGroup = routes.grouped("api", "crates", "id")
        
        singleCrateGroup.delete(":id", use: deleteHandler)
        singleCrateGroup.get(":id", use: getHandler)
        singleCrateGroup.get(":id", "acronyms", use: getAcronymsHandler)
        
        let searchGroup = routes.grouped("api", "crates", "search")
        
        searchGroup.get(":search", use: searchHandler)
        
        let paginateGroup = routes.grouped("api", "crates", "page")
        
        paginateGroup.get("", use: pageAll(req:))
    }
    
    func getModelID(_ req: Request) throws -> UUID {
        guard let id = req.parameters.get("id") else {
            throw Abort(.notFound)
        }
        guard let uuid = UUID(uuidString: id) else {
            throw Abort(.notFound)
        }
        return uuid
    }
    
    func getSearchTerm(_ req: Request) throws -> String {
        guard let searchTerm = req.parameters.get("search") else {
            throw Abort(.notFound)
        }
        return searchTerm
    }
    
    func getHandler(_ req: Request) async throws -> Crate {
        let id = try getModelID(req)
        guard let crate = try await Crate.find(id, on: req.db) else {
            throw Abort(.notFound)
        }
        return crate
    }
    
    private func all(req: Request) async throws -> [Crate] {
        ///This means that the first one created will be the first one to appear in the array
        ///if it is `.descending` then the first one will be the last to appear
        try await Crate.query(on: req.db).sort(\.$createdAt, .ascending).all()
    }
    
    private func pageAll(req: Request) async throws -> Page<Crate> {
        ///This means that the first one created will be the first one to appear in the array
        ///if it is `.descending` then the first one will be the last to appear
       return try await Crate.query(on: req.db).sort(\.$createdAt, .ascending).paginate(for: req)
    }
    
    private func create(req: Request) async throws -> Crate {
        // 1
        let crates = try req.content.decode(Crate.self)
        // 2
        try await crates.create(on: req.db)
        // 3
        return crates
    }
    
    private func update(req: Request) async throws -> Crate {

        let id = try getModelID(req)
        let updateData = try req.content.decode(CreateData.self)
        guard let crate = try await Crate.find(id, on: req.db) else {
            throw Abort(.notFound)
        }
        crate.owner = updateData.owner
        crate.item = updateData.item
       // crate.$crate.id = updateData.crateID
        try await crate.save(on: req.db)
        return crate
    }
    
    private func trade(req: Request) async throws -> HTTPStatus {
        let allTrades = try req.content.decode([TradeItem].self)
        return try await withThrowingTaskGroup(
            of: HTTPStatus.self
        ) { taskGroup in
            for tradingSides in allTrades {
                taskGroup.addTask {
                    try await tradeOne(on: req.db, tradingSides: tradingSides)
                }
            }
            
            try await taskGroup.waitForAll()
            
            return .ok
        }
    }
    
    private func tradeOne(
        on db: Database,
        tradingSides: TradeItem
    ) async throws -> HTTPStatus {
        let bothCrates = try await Crate.query(on: db)
            .filter(\.$id ~~ [tradingSides.firstId, tradingSides.secondId])
            .all()
        
        guard bothCrates.count == 2 else {
            throw Abort(.badRequest)
        }
        let crate1 = bothCrates[0]
        let crate2 = bothCrates[1]
        
        (crate1.owner, crate2.owner) = (crate2.owner, crate1.owner)
        
        async let crate1Saving: Void = crate1.save(on: db)
        async let crate2Saving: Void = crate2.save(on: db)
        _ = try await (crate1Saving, crate2Saving)
        
        return .ok
    }
    
    func getAcronymsHandler(_ req: Request) async throws -> [Acronym] {
        let id = try getModelID(req)
        guard let crate = try await Crate.find(id, on: req.db) else {
            throw Abort(.notFound)
        }
        return try await crate.$acronyms.get(on: req.db)
    }
    
    func deleteHandler(_ req: Request) async throws -> HTTPStatus {
        let id = try getModelID(req)
        guard let crate = try await Crate.find(id, on: req.db) else {
            throw Abort(.notFound)
        }
        do {
            try await crate.delete(on: req.db)
        } catch {
            throw Abort(.notFound)
        }
       return .ok
    }
    
    func searchHandler(_ req: Request) async throws -> [Crate] {
        let searchTerm = try getSearchTerm(req) 
        return try await Crate.query(on: req.db).group(.or) { or in
            or.filter(\.$owner ~~ searchTerm)
            or.filter(\.$item ~~ searchTerm)
        }.all()
    }
}

struct CreateData: Content {
    let owner: String
    let item: String
    let id: String
    //let crateID: UUID
}
