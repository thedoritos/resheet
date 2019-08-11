require "test/unit"
require "rack/test"
require "json"

OUTER_APP = Rack::Builder.parse_file('config.ru').first

class HomepageTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    OUTER_APP
  end

  def header
    { 'CONTENT_TYPE' => 'application/json' }
  end

  def json(params)
    JSON.generate(params)
  end

  def teardown
    delete '/animations/2'
  end

  def test_select_resource
    get '/animations'

    assert last_response.ok?
    assert_equal last_response.body, '[{"id":"1","title":"SHIROBAKO"}]'
  end

  def test_find_resource_by_id
    get '/animations/1'

    assert last_response.ok?
    assert_equal last_response.body, '{"id":"1","title":"SHIROBAKO"}'
  end

  def test_create_resource
    params = { title: "Charlotte" }
    post '/animations', params, {}

    assert last_response.created?
    assert_equal last_response.header['Location'], '/animations/2'

    get '/animations/2'

    assert last_response.ok?
    assert_equal last_response.body, '{"id":"2","title":"Charlotte"}'
  end
end
