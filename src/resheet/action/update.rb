module Resheet::Action
  class Update
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

      updating_record = data.find { |item| item['id'] == request.id }
      if updating_record.nil?
        return [404, { 'Content-Type' => 'application/json' }, ["{ \"error\": \"Object with id=#{request.id} is not found\" }"]]
      end

      updating_row = data.index(updating_record) + 2 # Records start from the row no.2

      updating_keys = header.reject { |key| key == 'id' }
                            .reject { |key| request.params[key].nil? }

      updating_keys.each do |key|
        updating_record[key] = request.params[key]
      end

      update = Google::Apis::SheetsV4::ValueRange.new
      update.range = "#{request.resource}!A#{updating_row}:Z#{updating_row}"
      update.values = [updating_record.values]

      @service.update_spreadsheet_value(@spreadsheet_id, update.range, update, value_input_option: 'USER_ENTERED')

      return [204, {}, []]
    end
  end
end
