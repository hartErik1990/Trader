//
//  File.swift
//  
//
//  Created by Civilgistics_Labs on 2/6/22.
//

import XCTVapor
import App

extension Application {
  static func testable() throws -> Application {
      let app = Application(.testing)
      do {
          try configure(app)
          try app.autoRevert().wait()
          try app.autoMigrate().wait()
      } catch {
          app.logger.critical("\(error)")
      }
 

    return app
  }
}
