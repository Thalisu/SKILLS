struct User {
    let id: Int
}

final class Svc {
    let retries: Int = 3

    init(retries: Int) {}

    func fetchUser(id: Int) -> User {
        return User(id: id)
    }
}
