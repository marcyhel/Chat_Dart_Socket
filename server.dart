import 'dart:io';
import 'dart:convert';

class Cliente {
  int id;
  String id_sala='';
  String nick = '';
  WebSocket conect;
  Cliente(this.id, this.conect){}
}
class Instancia{
  List<WebSocket> conect=[];
  List<String>historico=[];
  String id;
  Instancia(this.id){print("nova sala ${id}");}
  void add_cliente(WebSocket conec){
    
    conect.add(conec);
    conec.add(json.encode({'id':'ok'}));
    historico.forEach((e){
      conec.add(json.encode({'id':'msn','msn':json.decode(e)['msn'],'nick': json.decode(e)['nick']}));
      });
  }
  void remove(WebSocket soc){
    conect.remove(soc);
  }

  void sendOthers(mensagem,nick, WebSocket exeption) {
    print("send");
    historico.add(json.encode({'msn':mensagem,'nick':nick}));
    conect.forEach((element) {
      if (element != exeption) {
        element.add(json.encode({'id':'msn','msn':mensagem,'nick':nick}));
      }
    });
  }
}

class Sala {
  List<Cliente> clientes = [];
  List<Instancia> instanci=[];
  
  Sala() {}

  
  void iniciar_instancia(String id,){
    print("ddddff");
    var a=instanci.where((e){return (e.id == id);});
    print(a);
    if(a.length==0){
      instanci.add(Instancia(id));
    }
  }

  void chamadas(msns, client) {
    var msn = json.decode(msns);
    if (msn['id'] == 'nick') {
      client.nick = msn['nick'];
      client.id_sala=msn['id_sala'];
      iniciar_instancia(client.id_sala);
      instanci.forEach((e){
        if(e.id==client.id_sala){
          e.add_cliente(client.conect);
        }
        });
      /*sendOthers(
          json.encode({'id': 'nickOP', 'nick': client.nick}), client.conect);
      sendOthers(json.encode({'id': 'desenha'}), client.conect);
      sendOthers(json.encode({'id': 'vez', 'vez': vez_jogador}), client.conect);*/
    }
    if (msn['id'] == 'msn') {
        instanci.forEach((e){
          if(e.id==msn['id_sala']){
            e.sendOthers(msn['msn'],msn['nick'],client.conect);
          }
          });
        //client.conect
         //   .add(json.encode({'id': 'erro', 'erro': 'Não é sua vez de jogar'}));
      
    }
    if(msn['id']=="quit"){
      instanci.forEach((e){
          if(e.id==msn['id_sala']){
            e.remove(client.conect);
            print('remove');
          }
          });
    }
  }
  
  void add_cliente(newCliente){
      clientes.add(newCliente);
      newCliente.conect.listen((event) {
        print(event);
        
        chamadas(event, newCliente);
      });
      newCliente.conect.add(json.encode({'id': 'id', 'ident': newCliente.id}));
 
  }
  

  void sendOthers(mensagem, WebSocket exeption) {
    clientes.forEach((element) {
      if (element.conect != exeption) {
        element.conect.add(mensagem);
      }
    });
  }

  void sendAll(mensagem) {
    clientes.forEach((element) {
      element.conect.add(mensagem);
    });
  }

  void addCliente(cliente) {
    clientes.add(cliente);
  }
}

main() {
  List<Sala> salas = [];
  var sala = Sala();
  print('rodando');
  var port=int.parse(Platform.environment['PORT']??"8080");
  print(port);

  HttpServer.bind('0.0.0.0', port).then((server) {
    server.listen((HttpRequest request) {
      WebSocketTransformer.upgrade(request).then((cliente) {
        print("conect");
        
        sala.add_cliente(Cliente(sala.clientes.length + 1, cliente));

       
      });
      
    });
  });
}
