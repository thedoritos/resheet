require 'googleauth'
require 'google/apis/sheets_v4'
require 'json'
require 'resheet/request'
require 'resheet/process/select'
require 'resheet/process/find'

module Resheet; end

class Resheet::App
  SHEET_ID = ENV['RESTFUL_SHEET_ID']

  def call(env)
    credentials = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open('credentials.json'),
      scope: Google::Apis::SheetsV4::AUTH_SPREADSHEETS
    )
    credentials.fetch_access_token!

    request = Resheet::Request.new(env)

    service = Google::Apis::SheetsV4::SheetsService.new
    service.authorization = credentials
    begin
      values = service.get_spreadsheet_values(SHEET_ID, "#{request.resource}!A:Z").values
    rescue Google::Apis::ClientError => error
      return [500, { 'Content-Type' => 'application/json' }, ["{ \"error\": \"#{error.class}: #{error}\" }"]]
    end

    header = values[0]
    rows = values.drop(1)
    data = rows.map do |row|
      header.each_with_index.map { |key, i| [key, row[i]] }.to_h
    end

    if request.method == 'POST'
      new_record = header.map { |key| [key, request.params[key]] }.to_h
      new_record['id'] = data.map { |item| item['id'].to_i }.max + 1

      update = Google::Apis::SheetsV4::ValueRange.new
      update.range = "#{request.resource}!A:Z"
      update.values = [new_record.values]

      service.append_spreadsheet_value(SHEET_ID, update.range, update, value_input_option: "USER_ENTERED")

      return [201, { 'Content-Type' => 'application/json', 'Location' => "/#{request.resource}/#{new_record['id']}" }, []]
    end

    if ['PUT', 'PATCH'].include?(request.method)
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

      service.update_spreadsheet_value(SHEET_ID, update.range, update, value_input_option: 'USER_ENTERED')

      return [204, {}, []]
    end

    if request.method == 'DELETE'
      deleting_record = data.find { |item| item['id'] == request.id }
      if deleting_record.nil?
        return [404, { 'Content-Type' => 'application/json' }, ["{ \"error\": \"Object with id=#{request.id} is not found\" }"]]
      end

      sheet = service.get_spreadsheet(SHEET_ID).sheets.find { |sheet| sheet.properties.title == request.resource }
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

      service.batch_update_spreadsheet(SHEET_ID, batch)

      return [204, {}, []]
    end

    process = if request.id
      Resheet::Process::Find.new(service, SHEET_ID)
    else
      Resheet::Process::Select.new(service, SHEET_ID)
    end

    process.receive(request)
  end
end
