require 'resheet/response'

module Resheet::Action
  class Update
    def initialize(sheets_service, spreadsheet_id)
      @sheets_service = sheets_service
      @spreadsheet_id = spreadsheet_id
    end

    def invoke(request)
      sheet = Resheet::Sheet.new(@sheets_service, @spreadsheet_id, request.resource)
      sheet.fetch

      return Resheet::ServerErrorResponse.new(sheet.error) if sheet.error

      record = sheet.find_record(request.id)
      return Resheet::RecordNotFoundResponse.new({ id: request.id }) if record.nil?

      row = sheet.row_number_of(record)
      record = sheet.updated_record(request.params)

      update = Google::Apis::SheetsV4::ValueRange.new
      update.range = "#{request.resource}!A#{row}:Z#{row}"
      update.values = [record.values]

      @sheets_service.update_spreadsheet_value(@spreadsheet_id, update.range, update, value_input_option: 'USER_ENTERED')

      return Resheet::NoContentResponse.new
    end
  end
end
