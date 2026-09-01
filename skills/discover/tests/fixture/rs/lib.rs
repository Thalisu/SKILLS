pub const MAX_RETRIES: u32 = 3;

pub type UserId = u32;

pub struct User {
    pub id: UserId,
}

pub enum FetchError {
    NotFound,
}

pub trait Repository {
    fn find_user(&self, id: UserId) -> Option<User>;
}

pub struct Svc;

impl Svc {
    pub fn fetch_user(&self, id: UserId) -> Result<User, FetchError> {
        Ok(User { id })
    }
}
