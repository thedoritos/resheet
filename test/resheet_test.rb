require "test/unit"
require "rack/test"

OUTER_APP = Rack::Builder.parse_file('config.ru').first

class HomepageTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    OUTER_APP
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
end
