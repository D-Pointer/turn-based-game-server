import FluentSQLite
import Vapor

final class Turn: SQLiteModel {
    /// The unique identifier for this user
    var id: Int?

    /// the game the turn belongs to
    var gameId: Int

    // the raw data
    var data: Data

    // the sequence or turn (increases player count for each game turn)
    //var sequence: Int

    /// Creates a new `Todo`.
    init(id: Int? = nil, gameId: Int, data: Data /*sequence: Int*/) {
        self.id = id
        self.gameId = gameId
        self.data = data
        //self.sequence = sequence
    }
}

/// Allows `Turn` to be used as a dynamic migration.
extension Turn: Migration {
    //    static func prepare(on connection: SQLiteConnection) -> Future<Void> {
    //        return Database.create(self, on: connection) { builder in
    //            try addProperties(to: builder)
    //            builder.unique(on: \Turn.username)
    //        }
    //    }
}

/// Allows `Turn` to be encoded to and decoded from HTTP messages.
extension Turn: Content { }

/// Allows `Turn` to be used as a dynamic parameter in route definitions.
extension Turn: Parameter { }

//extension Turn: Validatable {
//    /// See `Validatable`.
//    static func validations() throws -> Validations<Turn> {
//        var validations = Validations(Turn.self)
//        try validations.add(\.mapSize, .range(10...250))
//        try validations.add(\.playerCount, .range(2...8))
//        try validations.add(\.openPositions, .range(0...))
//        return validations
//    }
//}
