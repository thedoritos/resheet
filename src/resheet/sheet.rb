module Resheet
  class Sheet
    attr_reader :error
    attr_reader :header, :rows, :data

    def initialize(sheets_service, spreadsheet_id, resource)
      @sheets_service = sheets_service
      @spreadsheet_id = spreadsheet_id
      @resource = resource
    end

    def fetch
      begin
        values = @sheets_service.get_spreadsheet_values(@spreadsheet_id, "#{@resource}!A:Z").values
        @header = values[0]
        @rows = values.drop(1)
        @data = @rows.map do |row|
          @header.each_with_index.map { |key, i| [key, row[i]] }.to_h
        end
      rescue Google::Apis::ClientError => error
        @error = error
      end
    end

    def new_record(params)
      record = @header.map { |key| [key, params[key]] }.to_h
      record['id'] = @data.map { |item| item['id'].to_i }.max + 1
      record
    end

    def find_record(id)
      @data.find { |item| item['id'] == id }
    end
  end
end
