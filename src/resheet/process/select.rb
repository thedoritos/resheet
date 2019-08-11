module Resheet::Process
  class Select
    def initialize(sheet_service, spreadsheet_id)
      @service = sheet_service
      @spreadsheet_id = spreadsheet_id
    end

    def receive(request)
      begin
        values = @service.get_spreadsheet_values(@spreadsheet_id, "#{request.resource}!A:Z").values
      rescue Google::Apis::ClientError => error
        return [500, { 'Content-Type' => 'application/json' }, ["{ \"error\": \"#{error.class}: #{error}\" }"]]
      end

      header = values[0]
      rows = values.drop(1)
      data = rows.map do |row|
        header.each_with_index.map { |key, i| [key, row[i]] }.to_h
      end

      [200, { 'Content-Type' => 'application/json' }, [JSON.generate(data)]]
    end
  end
end
