//
//  File.swift
//  
//
//  Created by Civilgistics_Labs on 2/8/22.
//

import Fluent
import Foundation

final class AcronymCategoriesPivot: Model {
    static let schema = "acronym-categories-pivot"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: FieldKeys.acronymID)
    var acronym: Acronym
    
    @Parent(key: FieldKeys.categoriesID)
    var categories: Categories
    
    init() {}
    
    init(id: UUID? = nil,
         acronym: Acronym,
         categories: Categories) throws {
        self.id = id
        self.$acronym.id = try acronym.requireID()
        self.$categories.id = try categories.requireID()
    }
}

extension AcronymCategoriesPivot {
    enum FieldKeys {
        static let acronymID: FieldKey = "acronymID"
        static let categoriesID: FieldKey = "categoriesID"
        static let createdAt: FieldKey = "created_at"
        static let updatedAt: FieldKey = "updated_at"
    }
}
