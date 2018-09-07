import Vapor
import Crypto

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    print("controllers")
    let userController = UserController()
    let gameController = GameController()

    print("routes")

    router.get("users", use: userController.index)
    router.post("register", use: userController.register)

    let middleWare = User.basicAuthMiddleware(using: BCryptDigest())

    // authenticated routes
    let authedGroup = router.grouped(middleWare)
    authedGroup.post("login", use: userController.login)
    authedGroup.get("allgames", use: gameController.allGames)
    authedGroup.get("games", use: gameController.userGames)
    authedGroup.post("create", use: gameController.createGame)
    authedGroup.get("join", Game.parameter, use: gameController.join)
    authedGroup.get("participants", Game.parameter, use: gameController.participants)
    authedGroup.post("submitturn", Game.parameter, use: gameController.saveTurn)
    authedGroup.get("getturn", Game.parameter, use: gameController.getTurn)
}
