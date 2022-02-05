# jwt-auth

## Background

This is a demo on how to implement a token based authentication scheme that
combines an in memory stored access token with a cookie based refresh token.

The idea behind this is that most tutorials on token based authentication
in APIs do not show how a single page application can securely handle
access tokens. Most tutorials short out and simply store the access
token in a browser's session/local storage. This opens up an
[XSS](https://en.wikipedia.org/wiki/Cross-site_scripting) security
vulnerability in the application and some tutorials even fail to mention this.
Most developers who learn from these tutorials either never get to
understand the problem on their hands or are just too lazy to go further
and learn of possible ways of mitigating this security hole.

After doing a bit of research I came to a solution that combines
an access token that's stored in memory and a refresh token that's stored
in an HTTP only cookie. The solution goes as follows:

1. Log into a backend application
2. The backend application returns two tokens
    - An access token that is to be used in making various requests to the
      backend (typically has a very short life span - 5 minutes for example).
      This is passed to the frontend in the response body and the frontend
      will keep this in memory where it can't be accessed by third parties
      (could be a variable within a closure or a store available with whatever
      frontend framework is in use)
    - A refresh token that is to be used to request a new access token when
      the current one expires or is lost after a browser reset or something.
      Typically this will be passed to the frontend through an HTTP only
      cookie with a scope limited to a path that will be used to request for
      new access tokens (although this scoping is not necessary since the
      refresh token will not be used anywhere else but it is still good
      practice). The word Cookies might have triggered
      [CSRF](https://en.wikipedia.org/wiki/Cross-site_request_forgery) war
      memories; I can assure you that it is not something you should worry
      about too much here because the worst an attacker will do to your
      application users' is to make them refresh access tokens.
3. Frontend uses access token for normal requests up until when it expires
   (backend should respond with a 401) or the token is lost (browser was
   closed or page was refreshed).
4. Frontend requests for a new token by hitting the end point for refreshing
   access tokens and goes back (2) above.

NOTE: This demo uses JWT for both the refresh token and access token, it's
just a matter of preference. The refresh token need not be a JWT. Have
something that will not exceed the 4KB cookie limit and you can easily
revoke access to.

## Implementation

This demo utilises [Crystal](https://crystal-lang.org/) for the backend and
plain old Javascript (no bells and whistles) on the frontend.

### Backend
On the backend the first place you want to look at is
[src/server.cr](./src/server.cr). There is some boiler plate at the top
that sets up things like Middleware and various filters, you can ignore
those things for now. Focus on the end points which are blocks starting
with verbs like `post`, and `get`. Below is a high level description of
some of the endpoints:

- `post "/auth/login"`: this is the entry point into any interactions with
   the backend. It takes a username and password then returns an access token
   in the response body plus a refresh token in an HTTP only cookie under
   the name `REFRESH`.
- `post "/auth/refresh-token": this end point simply provides a new access
   token to the frontend application.
- `delete "/auth/refresh-token": this invalidates the existing refresh token
  thus token refreshes are disabled until a new one is generated after a
  log in.
  
For the frontend you need to look at [public/index.html]. You can pretty
much ignore most of the HTML in this and go straight to the script on
line 14 (as at the time of writing). Notice that the entire application
is wrapped in a function that is passed as an event handler to
`window.onload`. The access token when received from the backend will only
be accessible within this function thus nothing from the outside can
access it. Next you will see a variable defined at the top of the function
named auth. That is where the access token will be stored. Within this
massive function are closures (functions) that set and read this auth
variable.

Next place I would recommend you is close to the end of the function on
line 126 (`await loadProfile()`). That is the starting point of this
application. All that function cares about is pulling the currently
logged in user's profile information. It makes use of a function called
`authenticateThen(...)` whose sole purpose is to ensure that whatever
HTTP request is passed to it, is executed within an authenticated session
(more on this later). If `loadProfile` fails for some reason the application
will automatically navigate to the login page (see the `catch` immediately
after `await loadProfile()`).

The next point of interest is the `authenticateThen(...)` function. This
function takes another function whose job is to execute any request that
requires authentication with the backend. `authenticateThen` will first
of all check if an access token is available in memory. If none is, it
will automatically attempt a token refresh then proceed to run the function
it was passed with headers that should be used to Authenticate the request.
It expects to receive a Response object (emitted by the fetch function)
which it checks for a 401 response status. If it finds a 401 the
`authenticateThen` process will be repeated a couple of times before
giving up. Notice that `authenticateThen` does not attempt to log in,
it only tries to refresh the token if possible. If it can't, it bails
out with an exception taking us back to where `loadProfile` was triggered
so that we attempt to log in.

The rest is up to you to follow the code to understand what it is doing.
For a similar thing but with NodeJS see
[this](https://github.com/benawad/jwt-auth-example). NOTE: This is not
meant for production, it is for educational purposes only. Take it as
a starting point for your understanding of this token based API
authentication stuff and maybe your introduction to
[Crystal](https://crystal-lang.org). If you have anything to add or
complain about, feel free to issue a pull request or raise an issue
and then have your rant in there. I promise to read whatever you have
to contribute but can't guarantee a response.

## Setup/usage

1. Install Crystal by following the instructions for your operating
   system [here](https://crystal-lang.org/install/).
2. Install dependencies:
    ```sh
    shards install
    ```
3. Run the damn thing:
    ```sh
    crystal run src/server.cr
    ```
4. Log in at http://localhost:3000 using the following credentials:
    username: admin
    password: password
5. Have fun with browser inspect (you won't see anything)... Try to
   refresh the page and observe the requests that are sent to the backend.
   Maybe take a look at session/local storage to look for an access token.
   You should be able to see the refresh token in cookies, however it
   won't be accessible to any Javascript.
## Contributing

1. Fork it (<https://github.com/your-github-user/jwt-auth/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [kwalter](https://github.com/kwalter94) - creator and maintainer
