require 'open3'
require 'json'

include DocumentParser
class CensusApi

  def call(document_type, document_number)
    response = nil
    get_document_number_variants(document_type, document_number).each do |variant|
      response = Response.new(get_response_body(document_type, variant))
      return response if response.valid?
    end
    response
  end

  class Response
    def initialize(body)
      @body = body
    end

    def valid?
      code = data[:codRetorno]
      return code.present? && ['00', '01'].include? code
    end

    private

      def data
        @body[:obtenerEstadoPadron]
      end
  end

  private

    def get_response_body(document_type, document_number)
      if end_point_available?
        out, err, st = Open3.capture3("python3", "/home/deploy/aux-soap.py", Rails.application.secrets.census_api_end_point, "obtenerEstadoPadron", "consulConsultas", "8R", document_number)
        aux = out.gsub("None", "null").gsub("\n", '').gsub('    ', '').gsub("'", '"')
        return JSON.parse(aux)
      else
        stubbed_response(document_type, document_number)
      end
    end

    def end_point_available?
      Rails.env.staging? || Rails.env.preproduction? || Rails.env.production?
    end

end
