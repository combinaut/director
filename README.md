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

### Source/Target Record
An alias can also be linked to a record at both the source and target end of the alias. Linked records allow for automatic updating of the corresponding path. When the record is saved, it runs a method that updates all incoming and outgoing aliases.

```ruby
class MyModel < ActiveRecord::Base
  has_aliased_paths canonical_path: :path # Accepts a symbol, proc, or object that responds to `#canonical_path`

  private

  def path
    # Return the path that routes to this record
  end
end
```

### Url params
Url "params" or "query" from the request will be passed on and merged with target path. Any url params in the target path
will be preserved.

### Chaining
Alias lookups will chain if an alias `target_path` points to `source_path` of another. A `Director::AliasChainLoop`
exception is raised if a cycle is detected in the alias chain in order to avoid infinite lookups.
A chain ends when there is no alias with a `source_path` matching the `target_path` of the last
alias found, or if the last alias found is has a `redirect` handler. A redirect alias ends the chain in order to force the browser to update its url, thus continuing the alias chain lookup in a second request.

## Constraints
There are several constraints that can be applied to limit which requests are handled. Each constraint consists of a
whitelist and a blacklist that can be independently configured.

### Format
The format constraint looks at the request extension. This can be used to ignore asset requests or only apply aliasing
to HTML requests.
```ruby
Director::Configuration.constraints.format.only = [:html, :xml]
# or
Director::Configuration.constraints.format.except = :jpg
```

### Source Path
The source constraint limits what can be entered as a source path in an `Alias`. This can be useful if you want to
prevent aliasing of certain routes, like an admin namespace for example. `only` and `except` are passed to `validates_format_of`
validations on the Alias model, and accept any patterns the `:with` and `:without` options of that validator.
```ruby
Director::Configuration.constraints.source_path.only = %r{\A/pages/}
# or
Director::Configuration.constraints.source_path.except = %r{\A/admin/}
```
NOTE: This constraint will also limit what requests perform an alias lookup. If a constraint is added, it will effectively
disable existing aliases that do not match the new constraint.

### Target Path
The target constraint limits what can be entered as a target path in an `Alias`. This can be useful if you want to
prevent aliasing of certain routes, like an admin namespace for example. `only` and `except` are passed to `validates_format_of`
validations on the Alias model, and accept any patterns the `:with` and `:without` options of that validator.
```ruby
Director::Configuration.constraints.target_path.only = %r{\A/pages/}
# or
Director::Configuration.constraints.target_path.except = %r{\A/admin/}
```

### Request
The request constraint yields the request itself to a given proc. This can be used to ignore asset requests or only
apply aliasing based on any aspect of the request, for example, params, host name, etc.<sup id="footnote_ref_1">[1](#footnote_1)</sup>

```ruby
Director::Configuration.constraints.request.only = ->(request) { request.params['my_param'] == 'false' }
# or
Director::Configuration.constraints.request.except = ->(request) { request.env['HTTP_HOST'] == 'testing.test' }
```

### Lookup Scope
The lookup scope constraint is applied using the `ActiveRecord::Base.merge` method to inject the scope into alias the
lookup query. The constraint should be a callable object, and is passed a `Rack::Request` object for the current request.
This can be used to scope alias lookups based on the request subdomain, or other request criteria.


```ruby
# Assuming you have added a `domain` column to the aliases table...
Director::Configuration.constraints.lookup_scope = lambda do |request|
  Director::Alias.where(domain: Domain.id_from_host(request.host))
end

# or returning a callable object for merging
Director::Configuration.constraints.lookup_scope = proc do
  -> { where(client: Client.current) }
end
```

## Request Information
Sometimes it may be useful to know what the request url was before Director modified it, or know if Director handled the
request or ignored it due to constraints.

```ruby
Director::Middleware.original_request_url(request) # => Original request url before Director handled it
Director::Middleware.handled_request?(request) # => Boolean indicating whether or not Director handled the request
```

## Upgrading from an older version

### 1.1.x to 1.2.0

Alias resolution is now case insensitive. All incoming paths are downcased before saving or resolving. If you have existing aliases, you should call `#save` on each one to trigger the path sanitizer which will downcase the saved paths so the the downcased paths coming in to the `#resolve` method.

## Footnotes
<span id="footnote_1">1.</span> By default, Director only handles GET and HEAD requests because the `redirect` handler cannot tell the browser to redirect a POST. The `proxy` handler could internally redirect a POST to an aliased target path, but this dichotomy adds too much complexity for it to be enabled out of the box. The constraints configuration gives you full control over which requests are handled by Director in your application. [↩](#footnote_ref_1)
