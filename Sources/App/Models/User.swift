import FluentSQLite
import Vapor
import Authentication

final class User: SQLiteModel {
    /// The unique identifier for this user
    var id: Int?

    /// unique username
    var username: String

    /// password
    var password: String

    /// Creates a new `Todo`.
    init(id: Int? = nil, username: String, password: String) {
        self.id = id
        self.username = username
        self.password = password
    }
}

/// Allows `User` to be used as a dynamic migration.
extension User: Migration {
    static func prepare(on connection: SQLiteConnection) -> Future<Void> {
        return Database.create(self, on: connection) { builder in
            try addProperties(to: builder)
            builder.unique(on: \User.username)
        }
    }
}

/**
 * A public version of a user without the password.
 **/
extension User {
    struct Public: Content {
        let id: Int
        let username: String
    }
}

/// Allows `User` to be encoded to and decoded from HTTP messages.
extension User: Content { }

/// Allows `User` to be used as a dynamic parameter in route definitions.
extension User: Parameter { }

extension User: BasicAuthenticatable {
    static var usernameKey: WritableKeyPath<User, String> {
        return \.username
    }
    static var passwordKey: WritableKeyPath<User, String> {
        return \.password
    }
}

extension User: Validatable {
    /// See `Validatable`.
    static func validations() throws -> Validations<User> {
        var validations = Validations(User.self)
        try validations.add(\.username, .email)
        try validations.add(\.password, .count(8...))
        return validations
    }
}
