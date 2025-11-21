import 'dart:convert';
import 'package:http/http.dart' as http;
import 'credenciais.dart'; // Importa as credenciais centralizadas

// As constantes já estão importadas de 'credenciais.dart'

/// Constrói a URL completa para um caminho
// Essa funçãozinha monta a URL completa pra gente, adicionando o '.json' no final,
// que é o que o Firebase exige para aceitar requisições REST (HTTP).
String buildUrl(String path) => '$FIREBASE_URL$path.json';

// FUNÇÕES DE ESCRITA
/// Envia comando para o ESP32 iniciar a pesagem
// Função que o app chama quando o usuário aperta o botão de "Iniciar Pesagem".
Future<bool> enviarComandoGerarPeso() async {
  // Monta a URL para o nosso path de comando.
  final url = Uri.parse(buildUrl(PATH_COMANDO));
  
  try {
    // Usamos o método HTTP PUT para ESCREVER o valor 'true' no Firebase.
    // jsonEncode(true) transforma o booleano 'true' em JSON.
    final res = await http.put(url, body: jsonEncode(true));
    
    // O Firebase retorna um código 200 (OK) se a escrita funcionou.
    if (res.statusCode == 200) {
      print('Comando enviado com sucesso!');
      return true;
    } else {
      // Se der qualquer outro código, deu ruim.
      print('Erro ao enviar comando: ${res.statusCode}');
      print(res.body); // Mostra o corpo da resposta de erro para debug.
      return false;
    }
  } catch (e) {
    // Captura erros de rede (tipo internet cair) ou outros erros inesperados.
    print('Erro ao enviar comando: $e');
    return false;
  }
}

/// Lê o peso atual diretamente do Firebase
// Função chamada para buscar o valor do peso que o ESP32 está mandando.
Future<double> lerPeso() async {
  // Monta a URL para o path do peso.
  final url = Uri.parse(buildUrl(PATH_PESO));
  
  try {
    // Usamos o método HTTP GET para LER o dado.
    final res = await http.get(url);
    
    if (res.statusCode == 200) {
      final body = res.body;
      
      // O ESP32 pode ter acabado de reiniciar, ou o dado ainda não foi setado.
      // Se o Firebase retornar 'null' ou um corpo vazio, a gente assume peso 0.0.
      if (body == 'null' || body.isEmpty) return 0.0;
      
      // Converte o corpo (que é um JSON) em um número Dart.
      // O 'as num' é para garantir que ele seja um número, e depois convertemos para double.
      final pesoLido = (jsonDecode(body) as num).toDouble();
      return pesoLido;

    } else {
      print('Erro ao ler peso: ${res.statusCode}');
    }
  } catch (e) {
    // Captura problemas na requisição (ex: falha de rede).
    print('Erro ao ler peso do Firebase: $e');
  }
  // Se qualquer coisa falhar, retornamos 0.0 para não quebrar o app.
  return 0.0;
}