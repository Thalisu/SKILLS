namespace Fixture
{
    public class Svc
    {
        public int Retries { get; set; } = 3;

        public User FetchUser(int id)
        {
            return new User(id);
        }
    }
}
