require "kemal"

require "./auth"
require "./auth_middleware"
require "./helpers"

add_handler AuthMiddleware::Handler.new

static_headers do |response, filepath, filestat|
  response.headers.add("Access-Control-Allow-Origin", "*") if filepath =~ /\.html$/
  response.headers.add("Content-Size", filestat.size.to_s)
end

before_all do |env|
  env.response.content_type = "application/json"
end

post "/auth/login" do |env|
  next render_error(env, "Username is required", status: 400) unless env.params.json["username"]?
  next render_error(env, "Password is required", status: 400) unless env.params.json["password"]?

  username = env.params.json["username"].as(String).strip
  password = env.params.json["password"].as(String).strip

  auth = Auth.login(username, password)
  next render_error(env, "Invalid username or password", status: 400) unless auth

  refresh_token_expires = Time.unix(Time.utc.to_unix + Auth::REFRESH_TOKEN_VALIDITY)
  set_cookie(env, "refresh", auth[:refresh_token], path: "/auth/refresh-token", http_only: true, expires: refresh_token_expires)

  render_json(env, { user: auth[:user], token: auth[:access_token] })
end

post "/auth/refresh-token" do |env|
  refresh_token = get_cookie(env, "refresh")
  next render_error(env, "User not logged in", status: 401) unless refresh_token

  user = Auth.validate_token(refresh_token)
  next render_error(env, "User not logged in", status: 401) unless user

  render_json(env, { user: user, token: Auth.generate_access_token(user) })
end

delete "/auth/refresh-token" do |env|
  set_cookie(env, "refresh", "", expires: Time.utc, path: "/auth/refresh-token", http_only: true)

  env.response.status_code = 204
end

get "/profile" do |env|
  render_json(env, { user: env.current_user, message: "Hello mortal" })
end

get "/" do |env|
  env.redirect("/index.html")
end

def start_server
  Kemal.run
end
