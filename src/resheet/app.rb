require 'googleauth'
require 'google/apis/sheets_v4'
require 'json'
require 'resheet/request'
require 'resheet/process/create'
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

    process = if request.method == 'POST'
      Resheet::Process::Create.new(service, SHEET_ID)
    elsif ['PUT', 'PATCH'].include?(request.method)
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
