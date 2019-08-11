require 'googleauth'
require 'google/apis/sheets_v4'
require 'json'
require 'resheet/request'
require 'resheet/process/select'
require 'resheet/process/find'
require 'resheet/process/update'
require 'resheet/process/delete'

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

    process = if ['PUT', 'PATCH'].include?(request.method)
      Resheet::Process::Update.new(service, SHEET_ID)
    elsif request.method == 'DELETE'
      Resheet::Process::Delete.new(service, SHEET_ID)
    elsif request.id
      Resheet::Process::Find.new(service, SHEET_ID)
    else
      Resheet::Process::Select.new(service, SHEET_ID)
    end

    process.receive(request)
  end
end
