#include "svc.hpp"

struct User { int id; };

class Svc {
public:
    User fetchUser(int id);
};

User Svc::fetchUser(int id) {
    return User{id};
}
