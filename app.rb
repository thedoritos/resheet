require 'googleauth'
require 'google/apis/sheets_v4'
require 'json'

class App
  SHEET_ID = ENV['RESTFUL_SHEET_ID']

  def call(env)
    credentials = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open('credentials.json'),
      scope: Google::Apis::SheetsV4::AUTH_SPREADSHEETS
    )
    credentials.fetch_access_token!

    request = Rack::Request.new(env)
    path_components = request.path_info.split('/').drop(1)
    resource = path_components[0]

    service = Google::Apis::SheetsV4::SheetsService.new
    service.authorization = credentials
    begin
      values = service.get_spreadsheet_values(SHEET_ID, "#{resource}!A:Z").values
    rescue Google::Apis::ClientError => error
      return [500, { 'Content-Type' => 'application/json' }, ["{ \"error\": \"#{error.class}: #{error}\" }"]]
    end

    header = values[0]
    rows = values.drop(1)
    data = rows.map do |row|
      header.each_with_index.map { |key, i| [key, row[i]] }.to_h
    end

    if request.request_method == 'POST'
      new_record = header.map { |key| [key, request.params[key]] }.to_h
      new_record['id'] = data.map { |item| item['id'].to_i }.max + 1

      update = Google::Apis::SheetsV4::ValueRange.new
      update.range = "#{resource}!A:Z"
      update.values = [new_record.values]

      service.append_spreadsheet_value(SHEET_ID, update.range, update, value_input_option: "USER_ENTERED")

      return [201, { 'Content-Type' => 'application/json', 'Location' => "/#{resource}/#{new_record['id']}" }, []]
    end

    if ['PUT', 'PATCH'].include?(request.request_method)
      id = path_components[1] || request.params['id']
      updating_record = data.find { |item| item['id'] == id }
      if updating_record.nil?
        return [404, { 'Content-Type' => 'application/json' }, ["{ \"error\": \"Object with id=#{id} is not found\" }"]]
      end

      updating_row = data.index(updating_record) + 2 # Records start from the row no.2

      updating_keys = header.reject { |key| key == 'id' }
                            .reject { |key| request.params[key].nil? }

      updating_keys.each do |key|
        updating_record[key] = request.params[key]
      end

      update = Google::Apis::SheetsV4::ValueRange.new
      update.range = "#{resource}!A#{updating_row}:Z#{updating_row}"
      update.values = [updating_record.values]

      service.update_spreadsheet_value(SHEET_ID, update.range, update, value_input_option: 'USER_ENTERED')

      return [204, {}, []]
    end

    if request.request_method == 'DELETE'
      id = path_components[1] || request.params['id']
      deleting_record = data.find { |item| item['id'] == id }
      if deleting_record.nil?
        return [404, { 'Content-Type' => 'application/json' }, ["{ \"error\": \"Object with id=#{id} is not found\" }"]]
      end

      sheet = service.get_spreadsheet(SHEET_ID).sheets.find { |sheet| sheet.properties.title == resource }
      if sheet.nil?
        return [500, { 'Content-Type' => 'application/json' }, ["{ \"error\": \"Sheet with title=#{resource} is not found\" }"]]
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

      service.batch_update_spreadsheet(SHEET_ID, batch)

      return [204, {}, []]
    end

    if path_components[1]
      id = path_components[1]
      data = data.find { |item| item['id'] == id }
      if data.nil?
        return [404, { 'Content-Type' => 'application/json' }, ["{ \"error\": \"Object with id=#{id} is not found\" }"]]
      end
    end

    [200, { 'Content-Type' => 'application/json' }, [JSON.generate(data)]]
  end
end
