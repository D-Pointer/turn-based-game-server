import Vapor

/// Creates an instance of Application. This is called from main.swift in the run target.
public func app(_ env: Environment) throws -> Application {
        print("app")

    var config = Config.default()
    var env = env
    var services = Services.default()

    print("services")
    try configure(&config, &env, &services)
    print("config")
    do {
        let app = try Application(config: config, environment: env, services: services)
        print("app")
        try boot(app)
        print("boot")
        return app
    }
    catch {
        print("Error setting up application: \(error).")
        throw error
    }
}
