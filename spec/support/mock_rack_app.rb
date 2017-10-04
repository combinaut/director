class MockRackApp
  attr_reader :env

  def call(env)
    @env = env
    [200, {}, ['OK']]
  end
end
