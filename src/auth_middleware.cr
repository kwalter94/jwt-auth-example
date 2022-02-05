require "kemal"

require "./auth"
require "./users"

module AuthMiddleware
  # Add accessor for authenticated user
  class HTTP::Server::Context
    property! current_user : Users::User
  end

  # Middleware for JWT authentication.
  class Handler < Kemal::Handler
    exclude ["/"], "GET"
    exclude ["/auth/login", "/auth/refresh-token"], "POST"
    exclude ["/auth/refresh-token"], "DELETE"

    def call(env : HTTP::Server::Context)
      return call_next(env) if exclude_match?(env)

      return auth_error(env, "No authentication token provided") unless env.request.headers["Authorization"]?

      token = env.request.headers["Authorization"].gsub(/^Bearer\s+/, "")
      user = Auth.validate_token(token)
      return auth_error(env, "Invalid or expired authentication token") unless user

      env.current_user = user
      call_next(env)
    end

    def auth_error(env, message)
      env.response.status_code = 401
      env.response.content_type = "application/json"
      env.response.print({ error: message }.to_json)
    end
  end
end
