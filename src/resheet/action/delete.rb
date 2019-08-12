module Resheet::Action
  class Delete
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

      deleting_record = sheet.find_record(request.id)
      if deleting_record.nil?
        return [404, { 'Content-Type' => 'application/json' }, ["{ \"error\": \"Object with id=#{request.id} is not found\" }"]]
      end

      gsheet = @sheets_service.get_spreadsheet(@spreadsheet_id).sheets.find { |gsheet| gsheet.properties.title == request.resource }
      if gsheet.nil?
        return [500, { 'Content-Type' => 'application/json' }, ["{ \"error\": \"Sheet with title=#{request.resource} is not found\" }"]]
      end

      deleting_row = sheet.row_number_of(deleting_record)

      delete = Google::Apis::SheetsV4::Request.new({
        delete_dimension: {
          range: {
            sheet_id: gsheet.properties.sheet_id,
            dimension: "ROWS",
            start_index: deleting_row - 1,
            end_index: deleting_row
          }
        }
      })

      batch = Google::Apis::SheetsV4::BatchUpdateSpreadsheetRequest.new
      batch.requests = [delete]

      @sheets_service.batch_update_spreadsheet(@spreadsheet_id, batch)

      return [204, {}, []]
    end
  end
end
