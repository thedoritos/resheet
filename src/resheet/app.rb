require 'googleauth'
require 'google/apis/sheets_v4'
require 'json'
require 'resheet/request'
require 'resheet/process/facade'

module Resheet; end

class Resheet::App
  SHEET_ID = ENV['RESTFUL_SHEET_ID']

  def call(env)
    credentials = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open('credentials.json'),
      scope: Google::Apis::SheetsV4::AUTH_SPREADSHEETS
    )
    credentials.fetch_access_token!

    service = Google::Apis::SheetsV4::SheetsService.new
    service.authorization = credentials

    request = Resheet::Request.new(env)

    process = Resheet::Process::Facade.new(service, SHEET_ID)
    process.receive(request)
  end
end
