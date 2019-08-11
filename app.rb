require 'googleauth'
require 'google/apis/sheets_v4'

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

    [200, { 'Content-Type' => 'application/json' }, ["{ \"values\": \"#{values}\" }"]]
  end
end
