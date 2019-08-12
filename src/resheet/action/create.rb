require 'resheet/sheet'

module Resheet::Action
  class Create
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

      new_record = sheet.new_record(request.params)

      update = Google::Apis::SheetsV4::ValueRange.new
      update.range = "#{request.resource}!A:Z"
      update.values = [new_record.values]

      @sheets_service.append_spreadsheet_value(@spreadsheet_id, update.range, update, value_input_option: "USER_ENTERED")

      return [201, { 'Content-Type' => 'application/json', 'Location' => "/#{request.resource}/#{new_record['id']}" }, []]
    end
  end
end
