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

    service = Google::Apis::SheetsV4::SheetsService.new
    service.authorization = credentials
    values = service.get_spreadsheet_values(ENV['RESTFUL_SHEET_ID'], 'animations!A:Z').values

    header = values[0]
    rows = values.drop(1)
    data = rows.map do |row|
      header.each_with_index.map { |key, i| [key, row[i]] }.to_h
    end

    [200, { 'Content-Type' => 'application/json' }, [JSON.generate(data)]]
  end
end
