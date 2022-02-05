module Users
  extend self

  class User
    getter id : Int32
    getter username : String

    def initialize(@id, @username, @password : String); end

    def password?(password)
      @password == password
    end

    def to_json(json_builder)
      { id: @id, username: @username }.to_json(json_builder)
    end
  end

  @@users  = { 1 => User.new(1, "admin", "password") }
  @@last_user_id = 1

  def create(username, password)
    raise "Username taken" if find_by_username(username)

    user_id = next_user_id
    user = User.new(user_id, username, password)
    users[user_id] = user

    user
  end

  def find_by_username(username)
    users.values.find { |user| user.username == username }
  end

  def find_by_id(id)
    users[id]
  end

  def delete(user)
    users.delete(user.id)
  end

  def users
    @@users
  end

  def next_user_id
    @@last_user_id += 1
  end
end
