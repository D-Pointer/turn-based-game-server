import FluentSQLite
import Vapor
import Authentication

final class Participant: SQLiteModel {
    /// The unique identifier for this participant
    var id: Int?

    /// the game id
    var gameId: Int

    /// the player id
    var userId: Int

    var playerOrder: Int

    /// Creates a new `Todo`.
    init(id: Int? = nil, gameId: Int, userId: Int, playerOrder: Int) {
        self.id = id
        self.gameId = gameId
        self.userId = userId
        self.playerOrder = playerOrder
    }
}

/// Allows `Participant` to be used as a dynamic migration.
extension Participant: Migration {
//    static func prepare(on connection: SQLiteConnection) -> Future<Void> {
//        return Database.create(self, on: connection) { builder in
//            try addProperties(to: builder)
//            builder.unique(on: \Participant.participantname)
//        }
//    }
}

/// Allows `Participant` to be encoded to and decoded from HTTP messages.
extension Participant: Content { }

/// Allows `Participant` to be used as a dynamic parameter in route definitions.
extension Participant: Parameter { }

//extension Participant: Validatable {
//    /// See `Validatable`.
//    static func validations() throws -> Validations<Participant> {
//        var validations = Validations(Participant.self)
//        try validations.add(\.participantname, .email)
//        try validations.add(\.password, .count(8...))
//        return validations
//    }
//}
