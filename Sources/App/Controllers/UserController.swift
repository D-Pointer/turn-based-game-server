import Vapor
import FluentSQLite
import Crypto

final class UserController {
    /// Returns a list of all users
    func index(_ req: Request) throws -> Future<[User]> {
        return User.query(on: req).all()
    }

    /**
     * Registers a new user. Parameters: username, password.
     **/
    func register(_ req: Request) throws -> Future<User.Public> {
        return try req.content.decode(User.self).flatMap { user in
            let hasher = try req.make(BCryptDigest.self)
            try user.validate()
            
            let passwordHashed = try hasher.hash(user.password)
            let newUser = User(username: user.username, password: passwordHashed)
            return newUser.save(on: req).map { storedUser in
                return User.Public(
                    id: try storedUser.requireID(),
                    username: storedUser.username
                )
            }
        }
    }

    /**
     * Logs in a user. The user is actually not logged in, this just checks that the user can log in with
     * provided credentials.
     **/
    func login(_ req: Request) throws -> User.Public {
        let user = try req.requireAuthenticated(User.self)
        return User.Public(id: try user.requireID(), username: user.username)
    }

    /// Saves a decoded user to the database.
//    func register(_ req: Request) throws -> Future<User> {
//        return try req.content.decode(User.self).flatMap { user in
//            try user.validate()
//            return user.save(on: req)
//        }
//    }

    /// Deletes a parameterized user
    func delete(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.parameters.next(User.self).flatMap { user in
            return user.delete(on: req)
            }.transform(to: .ok)
    }
}
