//
//  File.swift
//  
//
//  Created by Civilgistics_Labs on 2/6/22.
//

@testable import App
import Fluent

extension App.Crate {
  static func create(
    owner: String = "Luke",
    item: String = "lukes",
    on database: Database
  ) async throws -> Crate {
    let crate = Crate(owner: owner, item: item)
    try await crate.save(on: database)
    return crate
  }
}

extension App.Acronym {
  static func create(
    short: String = "TIL",
    long: String = "Today I Learned",
    crate: Crate? = nil,
    on database: Database
  ) async throws -> Acronym {
      var acronymsCrate = crate
    
    if crate == nil {
      acronymsCrate = try await Crate.create(on: database)
    }
    
    let acronym = Acronym(
      short: short,
      long: long,
      crateID: acronymsCrate!.id!)
    try await acronym.save(on: database)
      
    return acronym
  }
}

extension App.Categories {
  static func create(
    name: String = "Random",
    on database: Database
  ) async throws -> App.Categories {
      let categories = Categories(name: name)
      try await categories.save(on: database)
      return categories
  }
}
