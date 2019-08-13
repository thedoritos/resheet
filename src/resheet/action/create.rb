require 'resheet/response'
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

      return Resheet::ServerErrorResponse.new(sheet.error) if sheet.error

      new_record = sheet.new_record(request.params)

      update = Google::Apis::SheetsV4::ValueRange.new
      update.range = "#{request.resource}!A:Z"
      update.values = [new_record.values]

      @sheets_service.append_spreadsheet_value(@spreadsheet_id, update.range, update, value_input_option: "USER_ENTERED")

      return Resheet::NewRecordResponse.new(request.resource, new_record)
    end
  end
end
