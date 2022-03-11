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

struct CategoriesController: RouteCollection {
    
  func boot(routes: RoutesBuilder) throws {
    let categoriesRoute = routes.grouped("api", "categories")
    categoriesRoute.post(use: createHandler)
    categoriesRoute.get(use: getAllHandler)
    categoriesRoute.get(":id", use: getHandler)
    categoriesRoute.get(":id", "acronyms", use: getAcronymsHandler)
      
      let singleCategoriesGroup = routes.grouped("api", "categories", "id")
      
      singleCategoriesGroup.get(":id", use: getHandler)
      singleCategoriesGroup.delete(":id", use: deleteHandler)
      singleCategoriesGroup.put(":id", use: update(req:))
      singleCategoriesGroup.post(":id", "acronyms", ":acronyms", use: addAcronymsHandler)
      singleCategoriesGroup.delete(":id", "acronyms", ":acronyms", use: removeAcronymsHandler)
      singleCategoriesGroup.get(":id", "acronyms", use: getAcronymsForCategoriesHandler)

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
    
    func createHandler(_ req: Request) async throws -> Categories {
        let categories = try req.content.decode(Categories.self)
        // 2
       try await categories.create(on: req.db)
        // 3
        return categories
    }
    
  func getAllHandler(_ req: Request) async throws -> [Categories] {
      try await Categories
          .query(on: req.db)
          .sort(\.$createdAt, .ascending)
          .all()
  }
  
    func getHandler(_ req: Request) async throws -> Categories {
        let id = try getModelID(req)
        guard let categories = try await Categories.find(id, on: req.db) else {
            throw Abort(.notFound)
        }
        return categories
    }
  
  func getAcronymsHandler(_ req: Request) async throws -> [Acronym] {
      let id = try getModelID(req)
      guard let categories = try await Categories.find(id, on: req.db) else {
          throw Abort(.notFound)
      }
      let acronyms = try await categories.$acronyms.get(on: req.db)
      return acronyms
  }
    
    private func update(req: Request) async throws -> Categories {
        
        let updateData = try req.content.decode(CreateCategoriesData.self)
        let categories = try await getHandler(req)
        categories.name = updateData.name
    
        try await categories.save(on: req.db)
        return categories
    }
    
    func deleteHandler(_ req: Request) async throws -> HTTPStatus {
        let id = try getModelID(req)
        guard let categories = try await Categories.find(id, on: req.db) else {
            throw Abort(.notFound)
        }
        do {
            try await categories.delete(on: req.db)
        } catch {
            throw Abort(.notFound)
        }
       return .ok
    }
    
    func addAcronymsHandler(_ req: Request) async throws -> HTTPStatus {
        // 2
        /// /api/acronyms/id/<UUID for acronym>/categories/<UUID for categories>
        let categories = try await getHandler(req)
        guard let acronyms = try await Acronym.find(req.parameters.get("acronyms"), on: req.db) else {
            throw Abort(.notFound)
        }
        // 3
        do {
            try await categories.$acronyms.attach(acronyms, method: .ifNotExists, on: req.db)
        } catch {
            throw Abort(.notAcceptable)
        }
        return .ok
    }
    
    func removeAcronymsHandler(_ req: Request) async throws -> HTTPStatus {
        
        /// /api/acronyms/id/<UUID for acronym>/categories/<UUID for categories>
        let categories = try await getHandler(req)
        guard let acronyms = try await Acronym.find(req.parameters.get("acronyms"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        do {
            try await categories.$acronyms.detach(acronyms, on: req.db)
        } catch {
            throw Abort(.notAcceptable)
        }
        return .ok
        
    }
    
    func getAcronymsForCategoriesHandler(_ req: Request) async throws -> [Acronym] {
        let categories = try await getHandler(req)
        let acronyms = try await categories.$acronyms.get(on: req.db)
            .sorted(by: {$0.short > $1.short})
        return acronyms
    }
}

struct CreateCategoriesData: Content {
    let name: String
}
