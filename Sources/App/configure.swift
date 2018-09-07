import FluentSQLite
import Vapor
import Authentication

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    print("services")
    /// Register providers first
    try services.register(FluentSQLiteProvider())
    try services.register(AuthenticationProvider())
    
        print("router")

    /// Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)

    print("mw")

    /// Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    /// middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    services.register(middlewares)

    print("db")

    // Configure a SQLite database
    let sqlite = try SQLiteDatabase(storage: .file(path: "games.sqlite"))

    /// Register the configured SQLite database to the database config.
    var databases = DatabasesConfig()
    databases.add(database: sqlite, as: .sqlite)
    services.register(databases)

    print("migrations")

    /// Configure migrations
    var migrations = MigrationConfig()
    migrations.add(model: Game.self, database: .sqlite)
    migrations.add(model: User.self, database: .sqlite)
    migrations.add(model: Participant.self, database: .sqlite)
    migrations.add(model: Turn.self, database: .sqlite)
    services.register(migrations)
}
