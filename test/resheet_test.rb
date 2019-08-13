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

  def setup
    post '/animations', { title: 'SHIROBAKO' }, {}
  end

  def teardown
    delete '/animations/1'
    delete '/animations/2'
    delete '/animations/3'
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

  def test_update_resource
    params = { title: 'Sakura Quest' }
    patch '/animations/1', params, {}

    assert last_response.no_content?

    get '/animations/1'
    assert_equal last_response.body, '{"id":"1","title":"Sakura Quest"}'
  end

  def test_delete_resource
    params = { title: 'Hanasaku Iroha' }
    post '/animations', params, {}
    url = last_response.header['Location']

    get url
    assert last_response.ok?

    delete url
    assert last_response.no_content?

    get url
    assert last_response.not_found?
  end

  def test_error_when_sheet_is_not_found
    get '/null'

    assert last_response.server_error?
    assert_equal '{"error":"badRequest: Unable to parse range: null!A:Z"}', last_response.body
  end

  def test_error_when_record_to_find_is_not_found
    get '/animations/100'

    assert last_response.client_error?
    assert_equal '{"error":"Record with id=100 is not found"}', last_response.body
  end

  def test_error_when_record_to_update_is_not_found
    patch '/animations/100', { title: 'Glasslip' }

    assert last_response.client_error?
    assert_equal '{"error":"Record with id=100 is not found"}', last_response.body
  end

  def test_error_when_record_to_delete_is_not_found
    delete '/animations/100'

    assert last_response.client_error?
    assert_equal '{"error":"Record with id=100 is not found"}', last_response.body
  end
end
