module Resheet::Action
  class Create
    def initialize(sheet_service, spreadsheet_id)
      @service = sheet_service
      @spreadsheet_id = spreadsheet_id
    end

    def invoke(request)
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

      new_record = header.map { |key| [key, request.params[key]] }.to_h
      new_record['id'] = data.map { |item| item['id'].to_i }.max + 1

      update = Google::Apis::SheetsV4::ValueRange.new
      update.range = "#{request.resource}!A:Z"
      update.values = [new_record.values]

      @service.append_spreadsheet_value(@spreadsheet_id, update.range, update, value_input_option: "USER_ENTERED")

      return [201, { 'Content-Type' => 'application/json', 'Location' => "/#{request.resource}/#{new_record['id']}" }, []]
    end
  end
end
