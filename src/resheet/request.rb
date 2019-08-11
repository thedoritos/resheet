module Resheet
  class Request
    attr_reader :method, :resource, :id, :params

    def initialize(rack_env)
      rack_request = Rack::Request.new(rack_env)
      path_components = rack_request.path_info.split('/')

      @method = rack_request.request_method
      @resource = path_components[1]
      @id = path_components[2] || rack_request.params['id']
      @params = rack_request.params.merge({ 'id' => @id })
    end
  end
end
