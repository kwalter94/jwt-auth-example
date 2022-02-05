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
  username = env.params.json["username"].as(String).try(&.strip)
  password = env.params.json["password"].as(String).try(&.strip)

  next render_error(env, "Username is required", status: 400) unless username
  next render_error(env, "Password is required", status: 400) unless password

  auth = Auth.login(username, password)
  next render_error(env, "Invalid username or password", status: 400) unless auth

  set_cookie(env, "refresh", auth[:refresh_token], path: "/auth/refresh-token", http_only: true)
  render_json(env, { user: auth[:user], token: auth[:access_token] })
end

get "/auth/refresh-token" do |env|
  refresh_token = get_cookie(env, "refresh")
  next render_error(env, "User not logged in", status: 401) unless refresh_token

  user = Auth.validate_token(refresh_token)
  next render_error(env, "User not logged in", status: 401) unless user

  render_json(env, { user: user, token: Auth.generate_access_token(user) })
end

get "/" do |env|
  render_json(env, { user: env.current_user, message: "Hello mortal" })
end

def start_server
  Kemal.run
end
