require 'googleauth'
require 'google/apis/sheets_v4'
require 'json'
require 'resheet/request'
require 'resheet/router'

module Resheet
  class App
    def call(env)
      credentials = Google::Auth::ServiceAccountCredentials.make_creds(
        json_key_io: File.open('secrets/credentials.json'),
        scope: Google::Apis::SheetsV4::AUTH_SPREADSHEETS
      )
      credentials.fetch_access_token!

      service = Google::Apis::SheetsV4::SheetsService.new
      service.authorization = credentials

      router = Resheet::Router.new(service, ENV['RESHEET_SPREADSHEET_ID'])
      request = Resheet::Request.new(env)
      response = router.route(request)

      return response.to_rack
    end
  end
end
