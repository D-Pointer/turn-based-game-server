import FluentSQLite
import Vapor

final class Game: SQLiteModel {
    /// The unique identifier for this user
    var id: Int?

    /// player that created the game
    var owner: Int

    /// the size of one edge of the game map
    var mapSize: Int

    /// number of players that should be in the game
    var playerCount: Int

    // number of open positions in the game
    var openPositions: Int

    /// the next player in turn
    var nextPlayer: Int

    /// the current turn, 0..n
    var turn: Int

    enum State: Int, Codable {
        case open = 0
        case inProgress
        case finished
    }

    /// has the game started or is it waiting for players?
    var state: State

    /// Creates a new `Todo`.
    init(id: Int? = nil, owner: Int, mapSize: Int, playerCount: Int, openPositions: Int, nextPlayer: Int, state: State, turn: Int) {
        self.id = id
        self.owner = owner
        self.mapSize = mapSize
        self.playerCount = playerCount
        self.openPositions = openPositions
        self.nextPlayer = nextPlayer
        self.state = state
        self.turn = turn
    }
}

extension Game {
    // this game's turns
    var turns: Children<Game, Turn> {
        return children(\.gameId)
    }
}


/// Allows `Game` to be used as a dynamic migration.
extension Game: Migration {
//    static func prepare(on connection: SQLiteConnection) -> Future<Void> {
//        return Database.create(self, on: connection) { builder in
//            try addProperties(to: builder)
//            builder.unique(on: \Game.username)
//        }
//    }
}

/// Allows `Game` to be encoded to and decoded from HTTP messages.
extension Game: Content { }

/// Allows `Game` to be used as a dynamic parameter in route definitions.
extension Game: Parameter { }

extension Game: Validatable {
    /// See `Validatable`.
    static func validations() throws -> Validations<Game> {
        var validations = Validations(Game.self)
        try validations.add(\.mapSize, .range(10...250))
        try validations.add(\.playerCount, .range(2...8))
        try validations.add(\.openPositions, .range(0...))
        try validations.add(\.turn, .range(0...))
        return validations
    }
}
