import zeep
import sys

def get_soap_data(wsdl, method, id_aplicacion, id_usuario, identificador):
    client = zeep.Client(wsdl=wsdl)
    get_data = getattr(client.service, method)
    return get_data(id_aplicacion, id_usuario, identificador)


if __name__=="__main__":
    wsdl = sys.argv[1]
    method = sys.argv[2]
    id_aplicacion = sys.argv[3]
    id_usuario  = sys.argv[4]
    identificador = sys.argv[5]
    print(get_soap_data(wsdl, method, id_aplicacion, id_usuario, identificador))
