package fixture;

interface Repository {
    User lookupUser(int id);
}

public class Svc implements Repository {
    private final int retries;

    public Svc(int retries) {
        this.retries = retries;
    }

    public User lookupUser(int id) {
        return new User(id);
    }

    public User fetchUser(int id) {
        return lookupUser(id);
    }
}
