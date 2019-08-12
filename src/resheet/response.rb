module Resheet
  class Response
    def initialize(rack_response)
      @rack_response = rack_response
    end

    def rack_response
      @rack_response || [500, { 'Content-Type' => 'application/json' }, ['{ "error": "Not implemented" }']]
    end
  end
end
