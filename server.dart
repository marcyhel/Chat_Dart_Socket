import 'dart:io';
import 'dart:convert';

class Cliente {
  int id;
  String nick = '';
  WebSocket conect;
  Cliente(this.id, this.conect) {}
}

class Sala {
  List<Cliente> clientes = [];
  List<String> nick = [];
  int vez_jogador = 1;
  List<List<int>> tab = [
    [0, 0, 0],
    [0, 0, 0],
    [0, 0, 0]
  ];
  Sala() {}
  bool lance(x, y) {
    if (tab[x][y] == 0) {
      tab[x][y] = vez_jogador;
      return true;
    } else {
      return false;
    }
  }

  void alterna() {
    if (vez_jogador == 1) {
      vez_jogador = 2;
    } else {
      vez_jogador = 1;
    }
  }

  void chamadas(msns, client) {
    var msn = json.decode(msns);
    if (msn['id'] == 'nick') {
      client.nick = msn['nick'];
      sendOthers(
          json.encode({'id': 'nickOP', 'nick': client.nick}), client.conect);
      sendOthers(json.encode({'id': 'desenha'}), client.conect);
      sendOthers(json.encode({'id': 'vez', 'vez': vez_jogador}), client.conect);
    }
    if (msn['id'] == 'jogada') {
      if (client.id == vez_jogador) {
        try {
          var aux = msn['jogada'].split(' ');
          if (lance(int.parse(aux[0]), int.parse(aux[1]))) {
            sendAll(json.encode({
              'id': 'att',
              'x': int.parse(aux[0]),
              'y': int.parse(aux[1]),
              'marc': vez_jogador
            }));
            sendAll(json.encode({'id': 'desenha'}));
            alterna();
            sendAll(json.encode({'id': 'vez', 'vez': vez_jogador}));
          } else {
            client.conect.add(json.encode(
                {'id': 'erro', 'erro': 'jogada invalida\njogue novamente'}));
          }
        } catch (e) {
          client.conect
              .add(json.encode({'id': 'erro', 'erro': 'comando invalida'}));
        }
      } else {
        client.conect
            .add(json.encode({'id': 'erro', 'erro': 'Não é sua vez de jogar'}));
      }
    }
  }

  void inicia() {
    escutar();
    print("aquiiiop");
    clientes.forEach((e) {
      e.conect.add(json.encode({'id': 'id', 'ident': e.id}));
    });
  }

  void escutar() {
    clientes.forEach((element) {
      element.conect.listen((event) {
        print(event);
        // print("dd");
        //sendOthers(event, element.conect);
        chamadas(event, element);
      });
    });
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
        // cliente.add(sala.clientes.length.toString());

        if (sala.clientes.length < 2) {
          sala.addCliente(Cliente(sala.clientes.length + 1, cliente));
        }
        if (sala.clientes.length == 2) {
          //sala.sendAll("");
          sala.inicia();
          salas.add(sala);
          sala = Sala();
        }
      });
      //request.response.write('Hello, world!');
      //request.response.close();
    });
  });
}
