require 'resheet/process/create'
require 'resheet/process/read'
require 'resheet/process/update'
require 'resheet/process/delete'
require 'resheet/response'

module Resheet
  class Router
    def initialize(sheets_service, spreadsheet_id)
      @sheets_service = sheets_service
      @spreadsheet_id = spreadsheet_id
    end

    def route(request)
      process = case request.method
      when 'GET'
        Resheet::Process::Read.new(@sheets_service, @spreadsheet_id)
      when 'POST'
        Resheet::Process::Create.new(@sheets_service, @spreadsheet_id)
      when 'PUT', 'PATCH'
        Resheet::Process::Update.new(@sheets_service, @spreadsheet_id)
      when 'DELETE'
        Resheet::Process::Delete.new(@sheets_service, @spreadsheet_id)
      end

      Resheet::Response.new(process&.receive(request))
    end
  end
end
