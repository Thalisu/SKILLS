class Svc(private val retries: Int) {
    fun fetchUser(id: Int): User = User(id)
}

val onSave: (Int) -> Int = { value -> value * 2 }

data class User(val id: Int)
