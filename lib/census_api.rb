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
      code = data[:estadoPadron][:codRetorno]
      return code.present? && ['00', '01'].include? code
    end

    private

      def data
        @body
      end
  end

  private

    def get_response_body(document_type, document_number)
      if end_point_available?

        out_est, err_est, st_est = Open3.capture3("python3", "/home/deploy/aux-soap.py", Rails.application.secrets.census_api_end_point, "obtenerEstadoPadron", "consulConsultas", "8R", document_number)
        out_det, err_det, st_det = Open3.capture3("python3", "/home/deploy/aux-soap.py", Rails.application.secrets.census_api_end_point, "obtenerDetalle", "consulConsultas", "8R", document_number)

        aux_est = out_est.gsub("None", "null").gsub("\n", '').gsub('    ', '').gsub("'", '"')
        aux_det = out_det.gsub("None", "null").gsub("\n", '').gsub('    ', '').gsub("'", '"')

        estado = JSON.parse(aux_est)
        detalle = JSON.parse(aux_det)

        data["detallePadron"] = detalle
        data["estadoPadron"] = estado

        puts data
        @body = data
      else
        stubbed_response(document_type, document_number)
      end
    end

    def end_point_available?
      Rails.env.staging? || Rails.env.preproduction? || Rails.env.production?
    end

end
