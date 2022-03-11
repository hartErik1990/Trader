
import Vapor
import Fluent

final class Acronym: Model {
    
    static let schema = "acronyms"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: FieldKeys.short)
    var short: String
    
    @Field(key: FieldKeys.long)
    var long: String
    
    @Timestamp(key: FieldKeys.createdAt, on: .create)
    var createdAt: Date?
    
    @Timestamp(key: FieldKeys.updatedAt, on: .update)
    var updatedAt: Date?
    
    @Parent(key: FieldKeys.crateID)
    var crate: Crate
    
    @Siblings(through: AcronymCategoriesPivot.self, from: \.$acronym, to: \.$categories)
    var categories: [Categories]

    init() {}
    
    init(id: UUID? = nil,
         short: String, 
         long: String, 
         crateID: Crate.IDValue,
         createdAt: Date? = nil,
         updatedAt: Date? = nil) {
        self.id = id
        self.short = short
        self.long = long
        self.$crate.id = crateID
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
extension Acronym: Validatable {
    
    static func validations(_ validations: inout Validations) {
        validations.add(ValidationKeys.short, as: String.self, is: .count(7...) && .alphanumeric)
        validations.add(ValidationKeys.long, as: String.self, is: .count(4...) && .alphanumeric)
    }
}

extension Acronym: Content {}

// MARK: - FieldKeys
extension Acronym {
    enum FieldKeys {
        static let short: FieldKey = "short"
        static let long: FieldKey = "long"
        static let crateID: FieldKey = "crateID"
        static let createdAt: FieldKey = "created_at"
        static let updatedAt: FieldKey = "updated_at"
    }
    
    enum ValidationKeys {
        static let short: ValidationKey = "short"
        static let long: ValidationKey = "long"
        static let crateID: ValidationKey = "crateID"
        static let createdAt: ValidationKey = "created_at"
        static let updatedAt: ValidationKey = "updated_at"
    }
}

struct PagedAcronym: Content {
    
    let items: [Acronym]
    let metadata: Metadata
    
}
