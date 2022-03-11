//
//  File.swift
//
//
//  Created by Civilgistics_Labs on 2/6/22.
//
import Fluent

struct CreateCategories: AsyncMigration {
  func prepare(on database: Database) async throws {
    try await database
      .schema(Categories.schema)
      .id()
      .field(Categories.FieldKeys.name, .string, .required)

      .field(Categories.FieldKeys.createdAt, .datetime)
      .field(Categories.FieldKeys.updatedAt, .datetime)
      
      .create()
  }
  
  func revert(on database: Database) async throws {
    try await database
      .schema(Categories.schema)
      .delete()
  }
}
