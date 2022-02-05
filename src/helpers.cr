require "http"

def render_json(env, json, status = 200)
  env.response.status_code = status

  json.to_json
end

def render_error(env, message, status = 500)
  render_json(env, { error: message }, status: status)
end

def set_cookie(env, name, value, **options)
  cookie = HTTP::Cookie.new(**options, name: name, value: value)
  env.response.cookies << cookie
end

def get_cookie(env, name)
  return nil unless env.request.cookies[name]?

  env.request.cookies[name].value
end
