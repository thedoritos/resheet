module Resheet::Action
  class Read
    def initialize(sheets_service, spreadsheet_id)
      @sheets_service = sheets_service
      @spreadsheet_id = spreadsheet_id
    end

    def invoke(request)
      sheet = Resheet::Sheet.new(@sheets_service, @spreadsheet_id, request.resource)
      sheet.fetch

      if sheet.error
        return [500, { 'Content-Type' => 'application/json' }, ["{ \"error\": \"#{sheet.error.class}: #{sheet.error}\" }"]]
      end

      if request.id
        record = sheet.find_record(request.id)
        if record.nil?
          return [404, { 'Content-Type' => 'application/json' }, ["{ \"error\": \"Object with id=#{request.id} is not found\" }"]]
        end

        return [200, { 'Content-Type' => 'application/json' }, [JSON.generate(record)]]
      end

      [200, { 'Content-Type' => 'application/json' }, [JSON.generate(sheet.data)]]
    end
  end
end
