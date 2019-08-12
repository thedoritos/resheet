module Resheet::Action
  class Update
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

      updating_record = sheet.find_record(request.id)
      if updating_record.nil?
        return [404, { 'Content-Type' => 'application/json' }, ["{ \"error\": \"Object with id=#{request.id} is not found\" }"]]
      end

      updating_row = sheet.row_number_of(updating_record)
      updating_record = sheet.updated_record(request.params)

      update = Google::Apis::SheetsV4::ValueRange.new
      update.range = "#{request.resource}!A#{updating_row}:Z#{updating_row}"
      update.values = [updating_record.values]

      @sheets_service.update_spreadsheet_value(@spreadsheet_id, update.range, update, value_input_option: 'USER_ENTERED')

      return [204, {}, []]
    end
  end
end
