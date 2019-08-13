require 'resheet/response'

module Resheet::Action
  class Delete
    def initialize(sheets_service, spreadsheet_id)
      @sheets_service = sheets_service
      @spreadsheet_id = spreadsheet_id
    end

    def invoke(request)
      sheet = Resheet::Sheet.new(@sheets_service, @spreadsheet_id, request.resource)
      sheet.fetch

      return Resheet::ServerErrorResponse.new(sheet.error) if sheet.error

      record = sheet.find_record(request.id)
      return Resheet::ErrorResponse.new(404, "Record with id=#{request.id} is not found") if deleting_record.nil?

      gsheet = @sheets_service.get_spreadsheet(@spreadsheet_id).sheets.find { |gsheet| gsheet.properties.title == request.resource }
      return Resheet::ErrorResponse.new(500, "Sheet with title=#{request.resource} is not found") if gsheet.nil?

      row = sheet.row_number_of(record)

      delete = Google::Apis::SheetsV4::Request.new({
        delete_dimension: {
          range: {
            sheet_id: gsheet.properties.sheet_id,
            dimension: "ROWS",
            start_index: row - 1,
            end_index: row
          }
        }
      })

      batch = Google::Apis::SheetsV4::BatchUpdateSpreadsheetRequest.new
      batch.requests = [delete]

      @sheets_service.batch_update_spreadsheet(@spreadsheet_id, batch)

      return Resheet::NoContentResponse.new
    end
  end
end
