require 'resheet/response'

module Resheet::Action
  class Read
    def initialize(sheets_service, spreadsheet_id)
      @sheets_service = sheets_service
      @spreadsheet_id = spreadsheet_id
    end

    def invoke(request)
      sheet = Resheet::Sheet.new(@sheets_service, @spreadsheet_id, request.resource)
      sheet.fetch

      return Resheet::ServerErrorResponse.new(sheet.error) if sheet.error

      if request.id
        record = sheet.find_record(request.id)
        return Resheet::ErrorResponse.new(404, "Record with id=#{request.id} is not found") if record.nil?
        return Resheet::RecordResponse.new(record)
      end

      Resheet::RecordResponse.new(sheet.records)
    end
  end
end
