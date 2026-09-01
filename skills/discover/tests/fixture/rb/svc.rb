class Svc
  def self.fetch_user(id)
    User.new(id)
  end

  def retries
    3
  end
end
