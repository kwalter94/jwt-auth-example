require "jwt"
require "log"
require "time"

require "./users"

module Auth
  extend self

  alias User = Users::User

  Logger = Log.for("Auth")

  ACCESS_TOKEN_VALIDITY = 5 * 60 # Seconds
  REFRESH_TOKEN_VALIDITY = 60 * 60

  alias Credentials = NamedTuple(user: User, access_token: String, refresh_token: String)

  def login(username, password) : Credentials | Nil
    user = Users.find_by_username(username)
    return nil unless user && user.password?(password)

    {
      user: user,
      access_token: generate_access_token(user.id),
      refresh_token: generate_refresh_token(user.id)
    }
  end

  def generate_access_token(user_id : Int32)
    generate_token(user_id, ACCESS_TOKEN_VALIDITY)
  end

  def generate_refresh_token(user_id : Int32)
    generate_token(user_id, REFRESH_TOKEN_VALIDITY)
  end

  # Generate a token for user with given user_id for `validity` seconds.
  #
  # Returns generated token as a `String`
  def generate_token(user_id : Int32, validity : Int32)
    payload = { "user_id" => user_id, "exp" => Time.utc.to_unix + validity}
    JWT.encode(payload, secret, JWT::Algorithm::HS256)
  end

  # Validate a user token.
  #
  # Return user_id associated with that token or nil if the token is invalid
  def validate_token(token : String)
    payload, _headers = JWT.decode(token, secret, JWT::Algorithm::HS256)

    payload["user_id"].as_i?
  rescue e: JWT::DecodeError
    Logger.warn(exception: e) { "Failed to decode jwt" }
    nil
  end

  def secret
    "caput-draconis"
  end
end
