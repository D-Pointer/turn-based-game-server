import Vapor
import Fluent
import FluentSQLite
import NIO

final class GameController {
    /**
     * Returns a list of all games.
     **/
    func allGames(_ req: Request) throws -> Future<[Game]> {
        let _ = try req.requireAuthenticated(User.self)
        return Game.query(on: req).all()
    }

    /**
     * Returns a list of all users.
     **/
    func userGames(_ req: Request) throws -> Future<[Game]> {
        let user = try req.requireAuthenticated(User.self)
        let userId = try user.requireID()

        return Game.query(on: req).join(\Participant.gameId, to: \Game.id).filter(\Participant.userId == userId).all()
    }

    /**
     * Creates a new game based on JSON data and saves it to the database. Joins the player to the game.
     **/
    func createGame(_ req: Request) throws -> Future<Game> {
        let user = try req.requireAuthenticated(User.self)
        return try req.content.decode(Game.self).flatMap { game in
            let log = try req.make(Logger.self)
            let gameId = try game.requireID()
            let userId = try user.requireID()
            log.info("created game \(gameId), ")
            log.info("user \(userId) created game \(gameId), size: \(game.mapSize), players: \(game.playerCount)")

            return try self.joinGame(req: req, user: user, game: game)
        }
    }

    /**
     * Joins an already created game.
     **/
    func join(_ req: Request) throws -> Future<Game> {
        let user = try req.requireAuthenticated(User.self)
        return try req.parameters.next(Game.self).flatMap { game in
            let gameId = try game.requireID()
            let userId = try user.requireID()

            return Participant.query(on: req)
                .filter(\.userId == userId)
                .filter(\.gameId == gameId)
                .all()
                .flatMap { participants in
                    if !participants.isEmpty {
                        throw Abort(.badRequest, reason: "player already in the game")
                    }

                    // player not already a participant in the game, proceed with the join
                    return try self.joinGame(req: req, user: user, game: game)
            }
        }
    }

    func saveTurn(_ req: Request) throws -> Future<HTTPStatus> {
        let log = try req.make(Logger.self)

        let user = try req.requireAuthenticated(User.self)
        return try req.parameters.next(Game.self).flatMap { game in
            let gameId = try game.requireID()
            let userId = try user.requireID()

            // the game must be in progress
            guard game.state == .inProgress else {
                log.warning("user \(userId) tried to save a turn for game \(gameId), but it is not in progress")
                throw Abort(.badRequest, reason: "game is not in progress")
            }

            // at this stage the "next player" is still the player that should submit a turn
            guard userId == game.nextPlayer else {
                log.warning("user \(userId) tried to save a turn for game \(gameId), but not player's turn")
                throw Abort(.badRequest, reason: "not player's turn")
            }

            // the request must contain game data
            guard let body: Data = req.http.body.data else {
                log.warning("user \(userId) tried to save a turn for game \(gameId), but request contains no data")
                throw Abort(.badRequest, reason: "request contained no turn data")
            }

            return Participant.query(on: req).sort(\.playerOrder).all().flatMap { (participants) -> Future<HTTPStatus> in
                guard let playerOrder = participants.index( where: {$0.userId == userId }) else {
                    // this player was not found in the game
                    log.warning("user \(userId) tried to save a turn for game \(gameId), but not player not in the game")
                    throw Abort(.badRequest, reason: "player not in the game")
                }

                // update the next player
                game.nextPlayer = participants[ (playerOrder + 1) % game.playerCount].userId

                // save the updated game
                return game.save(on: req).flatMap { savedGame in
                    let turn = Turn(gameId: gameId, data: body)

                    return turn.save(on: req).flatMap { savedTurn in
                        let savedId = try savedTurn.requireID()
                        log.info("user \(userId) saved turn data \(savedId) for game \(gameId) for turn \(game.turn)")

                        // delete all other turns for this game
                        return Turn.query(on: req)
                            .filter(\.gameId == gameId)
                            .filter(\.id != savedId)
                            .delete()
                            .transform(to: .ok)
                    }
                }
            }
        }
    }

    func getTurn(_ req: Request) throws -> Future<HTTPResponse> {
        let log = try req.make(Logger.self)
        let user = try req.requireAuthenticated(User.self)
        let userId = try user.requireID()

        return try req.parameters.next(Game.self).flatMap { game in
            let gameId = try game.requireID()

            return Participant.query(on: req).sort(\.playerOrder).all().flatMap { participants in
                // make sure the player is in the game
                guard let _ = participants.index( where: {$0.userId == userId }) else {
                    // this player was not found in the game
                    log.warning("user \(userId) tried to save a turn for game \(gameId), but not player not in the game")
                    throw Abort(.badRequest, reason: "player not in the game")
                }

                // make sure this player is the next in turn
                guard userId == game.nextPlayer else {
                    log.warning("user \(userId) tried to get current turn for game \(gameId), but not player's turn")
                    throw Abort(.badRequest, reason: "not player's turn")
                }

                let gameId = try game.requireID()
                return Turn.query(on: req)
                    .filter( \Turn.gameId == gameId )
                    .first()
                    .unwrap(or: Abort(.badRequest, reason: "no turn found"))
                    .map(to: HTTPResponse.self) { turn in
                        let turnId = try turn.requireID()
                        log.info("user \(userId) fetched turn data \(turnId) for game \(gameId) for turn \(game.turn)")
                        return HTTPResponse(body: turn.data)
                }
            }
        }
    }

    private func joinGame(req: Request, user: User, game: Game) throws -> Future<Game> {
        if game.state != .open {
            throw Abort(.badRequest, reason: "game is not open")
        }
        if game.openPositions == 0 {
            throw Abort(.badRequest, reason: "game is full")
        }

        // the creating player takes one position in the game
        game.openPositions -= 1
        try game.validate()
        let gameId = try game.requireID()

        // the order is 0 for the fist player to join, 1 for the second etc
        let playerOrder = game.playerCount - game.openPositions - 1
        let log = try req.make(Logger.self)

        // enough players in the game?
        if playerOrder == game.playerCount - 1 {
            log.info("game \(gameId) is not full (\(game.playerCount) players) and can start")
            game.state = .inProgress
        }

        return game.save(on: req).flatMap { savedGame in
            let gameId = try game.requireID()
            let userId = try user.requireID()

            let participation = Participant(gameId: gameId, userId: userId, playerOrder: playerOrder)

            return participation.save(on: req).map { _ in
                return savedGame
            }
        }
    }

    /// Returns a list of all games
    func participants(_ req: Request) throws -> Future<[Participant]> {
        let _ = try req.requireAuthenticated(User.self)
        return try req.parameters.next(Game.self).flatMap { game in
            let gameId = try game.requireID()
            return Participant.query(on: req).filter(\Participant.gameId == gameId).sort(\.playerOrder).all()
        }
    }

    /// Deletes a parameterized game
    func delete(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.parameters.next(Game.self).flatMap { game in
            // TODO: delete turns and participants

            // delete from the database
            return game.delete(on: req)
            }.transform(to: .ok)
    }
}
