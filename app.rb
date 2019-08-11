class App
  def call(env)
    [200, { 'Content-Type' => 'application/json' }, ['{ "message": "hello" }']]
  end
end
