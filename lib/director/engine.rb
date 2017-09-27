# require 'director/controller_extensions'
require 'director/handlers/base'
require 'director/handlers/no_alias'
require 'director/handlers/proxy'
require 'director/handlers/redirect'

module Director
  class Engine < Rails::Engine
  end
end
