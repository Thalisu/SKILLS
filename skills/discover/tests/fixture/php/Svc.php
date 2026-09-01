<?php

function fetch_user(int $id): User
{
    return new User($id);
}

class Svc
{
    public function fetchUser(int $id): User
    {
        return fetch_user($id);
    }
}
