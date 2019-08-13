require 'resheet/action/read'
require 'resheet/action/create'
require 'resheet/action/update'
require 'resheet/action/delete'
require 'resheet/response'

module Resheet
  class Router
    def initialize(sheets_service, spreadsheet_id)
      @sheets_service = sheets_service
      @spreadsheet_id = spreadsheet_id
    end

    def route(request)
      action = case request.method
      when 'GET'
        Resheet::Action::Read.new(@sheets_service, @spreadsheet_id)
      when 'POST'
        Resheet::Action::Create.new(@sheets_service, @spreadsheet_id)
      when 'PUT', 'PATCH'
        Resheet::Action::Update.new(@sheets_service, @spreadsheet_id)
      when 'DELETE'
        Resheet::Action::Delete.new(@sheets_service, @spreadsheet_id)
      end

      action&.invoke(request)
    end
  end
end
