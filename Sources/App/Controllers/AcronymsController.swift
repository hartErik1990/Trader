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
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Vapor
import Fluent

struct AcronymsController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let acronymsRoutes = routes.grouped("api", "acronyms")
        
        acronymsRoutes.get(use: getAllHandler)
        acronymsRoutes.post(use: createHandler)
        
        acronymsRoutes.get(":id", "crate", use: getCrateHandler)
        
        let singleAcronymGroup = routes.grouped("api", "acronyms", "id")
        
        singleAcronymGroup.get(":id", use: getHandler)
        singleAcronymGroup.delete(":id", use: deleteHandler)
        singleAcronymGroup.put(":id", use: update(req:))
        singleAcronymGroup.patch(":id", use: patch(req:))
        singleAcronymGroup.post(":id", "categories", ":categories", use: addCategoriesHandler)
        singleAcronymGroup.delete(":id", "categories", ":categories", use: removeCategoriesHandler)
        singleAcronymGroup.get(":id", "categories", use: getCategoriesForAcronymHandler)
        
        let searchGroup = routes.grouped("api", "acronyms", "search")
        
        searchGroup.get(":search", use: searchHandler)
        
        let paginateGroup = routes.grouped("api", "acronyms", "page")
        
        paginateGroup.get("", use: pageAll(req:))
    }
    
    func getAllHandler(_ req: Request) async throws -> [Acronym] {
        try await Acronym.query(on: req.db).all()
    }
    
    func createHandler(_ req: Request) async throws -> Acronym {
        try Acronym.validate(content: req)
        let acronym = try req.content.decode(Acronym.self)
        // 2
        try await acronym.create(on: req.db)
        // 3
        return acronym
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
    
    func getHandler(_ req: Request) async throws -> Acronym {
        let id = try getModelID(req)
        guard let acronym = try await Acronym.find(id, on: req.db) else {
            throw Abort(.notFound)
        }
        return acronym
    }
    
    private func update(req: Request) async throws -> Acronym {
        try Acronym.validate(content: req)
        let updateData = try req.content.decode(CreateAcronymData.self)
        let acronym = try await getHandler(req)
        acronym.short = updateData.short
        acronym.long = updateData.long
        acronym.$crate.id = updateData.crateID
        try await acronym.save(on: req.db)
        return acronym
    }
    
    private func patch(req: Request) async throws -> Acronym {
        try Acronym.validate(content: req)
        let patchData = try req.content.decode(PatchAcronymData.self)
        let acronym = try await getHandler(req)
        
        acronym.short = patchData.short ?? acronym.short
        acronym.long = patchData.short ?? acronym.long
        
        try await acronym.save(on: req.db)
        return acronym
    }
    
    func deleteHandler(_ req: Request) async throws -> HTTPStatus {
        let acronym = try await getHandler(req)
        do {
            try await acronym.delete(on: req.db)
        } catch {
            throw Abort(.notFound)
        }
        return .ok
    }
    
    func getSearchTerm(_ req: Request) throws -> String {
        guard let searchTerm = req.parameters.get("search") else {
            throw Abort(.notFound)
        }
        return searchTerm
    }
    
    func searchHandler(_ req: Request) async throws -> [Acronym] {
        let searchTerm = try getSearchTerm(req)
        return try await Acronym.query(on: req.db).group(.or) { or in
            or.filter(\.$short ~~ searchTerm)
            or.filter(\.$long ~~ searchTerm)
        }
        .sort(\.$createdAt)
        .all()
    }
    
    func removeCategoriesHandler(_ req: Request) async throws -> HTTPStatus {
        
        /// /api/acronyms/id/<UUID for acronym>/categories/<UUID for categories>
        let acronym = try await getHandler(req)
        
        guard let category = try await Categories.find(req.parameters.get("categories"), on: req.db) else {
            throw Abort(.notFound)
        }
        do {
            try await acronym.$categories.detach(category, on: req.db)
        } catch {
            throw Abort(.notAcceptable)
        }
        return .ok
        
    }
    
    func getCategoriesForAcronymHandler(_ req: Request) async throws -> [Categories] {
        let acronym = try await getHandler(req)
        let categories = try await acronym.$categories.get(on: req.db)
            .sorted(by: {$0.name > $1.name})
        return categories
    }
    
    func getCrateHandler(_ req: Request) async throws -> Crate {
        let acronym = try await getHandler(req)
        return try await acronym.$crate.get(on: req.db)
    }
    
    private func pageAll(req: Request) async throws -> Page<Acronym> {
        ///This means that the first one created will be the first one to appear in the array
        ///if it is `.descending` then the first one will be the last to appear
        return try await Acronym.query(on: req.db).sort(\.$createdAt, .ascending).paginate(for: req)
    }
    
    func addCategoriesHandler(_ req: Request) async throws -> HTTPStatus {
        // 2
        /// /api/acronyms/id/<UUID for acronym>/categories/<UUID for categories>
        let acronym = try await getHandler(req)
        guard let category = try await Categories.find(req.parameters.get("categories"), on: req.db) else {
            throw Abort(.notFound)
        }
        // 3
        do {
            try await acronym.$categories.attach(category, method: .ifNotExists, on: req.db)
        } catch {
            throw Abort(.notAcceptable)
        }
        return .ok
    }
}

struct CreateAcronymData: Content {
    let short: String
    let long: String
    let crateID: UUID
}

struct PatchAcronymData: Content {
    let short: String?
    let long: String?
    let crateID: UUID?
}

