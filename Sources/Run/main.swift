//import App

do {
    print("Server starting...")

    try app(.detect()).run()
    print("Server done")
}
catch {
    print("Unexpected error: \(error).")
}
