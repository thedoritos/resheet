require 'googleauth'
require 'google/apis/sheets_v4'

class App
  def call(env)
    credentials = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open('credentials.json'),
      scope: Google::Apis::SheetsV4::AUTH_SPREADSHEETS_READONLY
    )
    credentials.fetch_access_token!

    [200, { 'Content-Type' => 'application/json' }, ["{ \"credentials\": \"#{credentials.to_yaml}\" }"]]
  end
end
