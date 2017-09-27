require 'director/middleware'

module Director
  class Railtie < Rails::Railtie
    initializer "director.init" do |app|
      app.config.middleware.use Director::Middleware
    end
  end
end
