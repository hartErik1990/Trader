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

import FluentPostgresDriver
import Vapor

public func configure(_ app: Application) throws {
    
    let databaseName: String
    let databasePort: Int
    // 1
    if (app.environment == .testing) {
        databaseName = "vapor-test"
        databasePort = 5433
    } else {
        databaseName = "vapor_database"
        databasePort = 5432
    }
    
    app.databases.use(.postgres(
      hostname: Environment.get("DATABASE_HOST")
        ?? "localhost",
      port: databasePort,
      username: Environment.get("DATABASE_USERNAME")
        ?? "vapor_username",
      password: Environment.get("DATABASE_PASSWORD")
        ?? "vapor_password",
      database: Environment.get("DATABASE_NAME")
        ?? databaseName
    ), as: .psql)
    
    app.migrations.add(CreateCrate())
    app.migrations.add(CreateAcronym())
    app.migrations.add(CreateCategories())
    app.migrations.add(CreateAcronymCategoriesPivot())
    app.migrations.add(CreateAirport())
    app.migrations.add(CreateFlight())
    app.migrations.add(CreateDevice())
    
    app.logger.logLevel = .debug
    
    app.http.server.configuration.hostname = "127.0.0.1"
    app.http.server.configuration.port = 9090
    
    try app.autoMigrate().wait()
   // try apns(app)
    try routes(app)
    try app.configurePush()
}
