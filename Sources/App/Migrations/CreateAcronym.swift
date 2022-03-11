//
//  File.swift
//  
//
//  Created by Civilgistics_Labs on 2/6/22.
//
import Fluent

struct CreateAcronym: AsyncMigration {
  func prepare(on database: Database) async throws {
    try await database
      .schema(Acronym.schema)
      .id()
      .field(Acronym.FieldKeys.short, .string, .required)
      .field(Acronym.FieldKeys.long, .string, .required)
      .field(Acronym.FieldKeys.crateID, .uuid, .required, .references("crates", "id"))
      
      .field(Acronym.FieldKeys.createdAt, .datetime)
      .field(Acronym.FieldKeys.updatedAt, .datetime)

      .create()
  }
  
  func revert(on database: Database) async throws {
    try await database
      .schema(Acronym.schema)
      .delete()
  }
}
