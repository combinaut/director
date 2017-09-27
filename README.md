# Director

Director is a Rack Middleware gem that directs incoming requests to their aliased target paths based on a customizable
alias list stored in the database. It has two basic handlers, but can be extended with your own.

## Usage

### Proxy
If you want to create a vanity path, where the contents of one page appears at a new path, use a `proxy` handler. The user agent will show the vanity path in the url bar, but the contents of the target path will appear on the page.
```ruby
Director::Alias.create(source_path: '/vanity/path', target_path: 'real/path', handler: :proxy)
```

### Redirect
If you want to redirect a deprecated or non-canonical path to the canonical path, use a `redirect` handler. The user agent will show the target path in the url bar and the contents of the target path will appear on the page.
```ruby
Director::Alias.create(source_path: '/deprecated/path', target_path: 'new/path', handler: :redirect)
```

### Custom Alias Handlers
You can create handlers for your own custom aliases. Handlers must be namespaced under `Director::Handler` and need only
implement a single `response` method. For those who have played with Rack, you will find the `response` method is very
similar to Rack's `MiddleWare#call` method in that it must return a Rack-compatible response. See https://rack.github.io/
for more information on valid return values, and the `lib/direct/handlers` folder basic for handler examples.

```ruby
class Director::Handler::MyCustomHandler < Base
  def response(app, env)
    # do some amazing stuff, then...
    # return a valid Rack response
  end
end
```
