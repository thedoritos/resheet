module Resheet
  class Response
    def json_header
      { 'Content-Type' => 'application/json' }
    end
  end

  class ErrorResponse < Response
    def initialize(status_code, error_message)
      @status_code = status_code
      @error_message = error_message
    end

    def to_rack
      [@status_code, json_header, ["{ \"error\": \"#{@error_message}\" }"]]
    end
  end

  class ServerErrorResponse < Response
    def initialize(error)
      @error = error
    end

    def to_rack
      [500, json_header, ["{ \"error\": \"#{@error}\" }"]]
    end
  end

  class NoContentResponse < Response
    def to_rack
      [204, {}, []]
    end
  end

  class RecordResponse < Response
    def initialize(record)
      @record = record
    end

    def to_rack
      [200, json_header, [JSON.generate(@record)]]
    end
  end

  class NewRecordResponse < Response
    def initialize(resource, record)
      @resource = resource
      @record = record
    end

    def to_rack
      [201, json_header.merge({ 'Location' => "/#{@resource}/#{@record['id']}" }), []]
    end
  end
end
