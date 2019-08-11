require 'resheet/process/create'
require 'resheet/process/select'
require 'resheet/process/find'
require 'resheet/process/update'
require 'resheet/process/delete'

module Resheet::Process
  class Facade
    def initialize(sheet_service, spreadsheet_id)
      @service = sheet_service
      @spreadsheet_id = spreadsheet_id
    end

    def receive(request)
      process = case request.method
      when 'GET'
        if request.id
          Resheet::Process::Find.new(@service, @spreadsheet_id)
        else
          Resheet::Process::Select.new(@service, @spreadsheet_id)
        end
      when 'POST'
        Resheet::Process::Create.new(@service, @spreadsheet_id)
      when 'PUT', 'PATCH'
        Resheet::Process::Update.new(@service, @spreadsheet_id)
      when 'DELETE'
        Resheet::Process::Delete.new(@service, @spreadsheet_id)
      end

      process&.receive(request)
    end
  end
end
