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
      data[:estadoPadron][:codRetorno]
      # return code.present? && ['00', '01'].include? code
    end

    def posta_code
      data[:detallePadron][:detallePadron][:cPostal]
    end

    def gender
      case data[:detallePadron][:detallePadron][:sexo]
      when "MUJER"
        "female"
      else
        "male"
      end
    end

    def date_of_birth
      data[:detallePadron][:detallePadron][:fechaNacimiento]
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

        data = {}

        data["detallePadron"] = detalle
        data["estadoPadron"] = estado
        data
      else
        stubbed_response(document_type, document_number)
      end
    end

    def end_point_available?
      Rails.env.staging? || Rails.env.preproduction? || Rails.env.production?
    end

    def stubbed_response(document_type, document_number)
      if document_number == "12345678" && document_type == "1"
        stubbed_valid_response
      else
        stubbed_invalid_response
      end
    end

    def stubbed_valid_response
      {
        "detallePadron": {
          "detallePadron": {
            "anioLlegada": "2019",
            "apellido1": "PRUEBA",
            "apellido2": "PRUEBA",
            "barrio": "SAN LORENZO",
            "bis": nil,
            "bloque": nil,
            "carnetPadronal": "0688331",
            "complementoVia": nil,
            "direccion": "CL MATARRATONES  ",
            "email": nil,
            "entidad": "CORDOBA - CORDOBA",
            "escalera": nil,
            "fechaDocumento": "07/03/2019",
            "fechaNacimiento": "01/03/1995",
            "identificador": "99999999R",
            "km": "0000",
            "movil": nil,
            "municipioNacimiento": "CÓRDOBA",
            "municipioOd": nil,
            "nacionalidad": "ESPAÑA",
            "nivelEstudios": "GRADUADO ESCOLAR O EQUIVALENTE",
            "nombre": "PRUEBA",
            "nombreCompleto": "PRUEBA PRUEBA PRUEBA",
            "numero": "0002",
            "ordenFamiliar": "001",
            "piso": "1",
            "portal": nil,
            "provinciaNacimiento": "CÓRDOBA",
            "provinciaOd": nil,
            "puerta": "1",
            "sexo": "MUJER",
            "siglas": nil,
            "telefono": nil,
            "tipoDocumento": "ALTA POR OMISION",
            "tipoIdentificador": "DNI/NIF",
            "tipoVivienda": "FAMILIAR",
            "viaCompleta": "CL MATARRATONES  , Nº: 0002, Pla. 1, Pta. 1",
            "cPostal": "14001"
          },
          "familiares": [
      
          ],
          "mensaje": "OK"
        },
        "estadoPadron": {
          "carnetPadronal": "0688331",
          "codRetorno": "01",
          "desRetorno": "DNI EN BASE Y NO EN HISTORICO",
          "nombreApellidos": "PRUEBA PRUEBA PRUEBA"
        }
      }      
    end

    def stubbed_invalid_response
      {
        "detallePadron": {
          "detallePadron": {
            "anioLlegada": nil,
            "apellido1": nil,
            "apellido2": nil,
            "barrio": nil,
            "bis": nil,
            "bloque": nil,
            "carnetPadronal": nil,
            "complementoVia": nil,
            "direccion": nil,
            "email": "No disponible.",
            "entidad": nil,
            "escalera": nil,
            "fechaDocumento": nil,
            "fechaNacimiento": nil,
            "identificador": nil,
            "km": nil,
            "movil": "No disponible.",
            "municipioNacimiento": nil,
            "municipioOd": nil,
            "nacionalidad": nil,
            "nivelEstudios": nil,
            "nombre": nil,
            "nombreCompleto": nil,
            "numero": nil,
            "ordenFamiliar": nil,
            "piso": nil,
            "portal": nil,
            "provinciaNacimiento": nil,
            "provinciaOd": nil,
            "puerta": nil,
            "sexo": nil,
            "siglas": nil,
            "telefono": "No disponible.",
            "tipoDocumento": nil,
            "tipoIdentificador": nil,
            "tipoVivienda": nil,
            "viaCompleta": nil,
            "cPostal": nil
          },
          "familiares": [
      
          ],
          "mensaje": "EL IDENTIFICADOR 99999990R NO SE HA ENCONTRADO"
        },
        "estadoPadron": {
          "carnetPadronal": "0000000",
          "codRetorno": "03",
          "desRetorno": "DNI NO EN BASE E HISTORICO",
          "nombreApellidos": nil
        }
      }
    end

    def dni?(document_type)
      document_type.to_s == "1"
    end
end
