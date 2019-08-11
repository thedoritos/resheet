require 'googleauth'
require 'google/apis/sheets_v4'
require 'json'

class App
  def call(env)
    credentials = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open('credentials.json'),
      scope: Google::Apis::SheetsV4::AUTH_SPREADSHEETS_READONLY
    )
    credentials.fetch_access_token!

    request = Rack::Request.new(env)
    path_components = request.path_info.split('/').drop(1)
    resource = path_components[0]

    service = Google::Apis::SheetsV4::SheetsService.new
    service.authorization = credentials
    begin
      values = service.get_spreadsheet_values(ENV['RESTFUL_SHEET_ID'], "#{resource}!A:Z").values
    rescue Google::Apis::ClientError => error
      return [500, { 'Content-Type' => 'application/json' }, ["{ \"error\": \"#{error.class}: #{error}\" }"]]
    end

    header = values[0]
    rows = values.drop(1)
    data = rows.map do |row|
      header.each_with_index.map { |key, i| [key, row[i]] }.to_h
    end

    [200, { 'Content-Type' => 'application/json' }, [JSON.generate(data)]]
  end
end
