module Resheet::Action
  class Delete
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

      deleting_record = data.find { |item| item['id'] == request.id }
      if deleting_record.nil?
        return [404, { 'Content-Type' => 'application/json' }, ["{ \"error\": \"Object with id=#{request.id} is not found\" }"]]
      end

      sheet = @service.get_spreadsheet(@spreadsheet_id).sheets.find { |sheet| sheet.properties.title == request.resource }
      if sheet.nil?
        return [500, { 'Content-Type' => 'application/json' }, ["{ \"error\": \"Sheet with title=#{request.resource} is not found\" }"]]
      end

      deleting_row = data.index(deleting_record) + 1 # Records start from the row index 1

      delete = Google::Apis::SheetsV4::Request.new({
        delete_dimension: {
          range: {
            sheet_id: sheet.properties.sheet_id,
            dimension: "ROWS",
            start_index: deleting_row,
            end_index: deleting_row + 1
          }
        }
      })

      batch = Google::Apis::SheetsV4::BatchUpdateSpreadsheetRequest.new
      batch.requests = [delete]

      @service.batch_update_spreadsheet(@spreadsheet_id, batch)

      return [204, {}, []]
    end
  end
end
