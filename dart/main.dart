import 'dart:io'; 
import 'app.dart' as app;  // Importa todos os componentes (classes e funções) da nossa aplicação.

Future<void> main() async {
  // === 1. Prepara a Conexão com o Banco ===
  
  // Cria uma instância da classe que cuida do banco de dados (que tá lá no 'app.dart').
  var db = app.Database(); 
  
  try {
    // Tenta abrir a conexão.
    await db.connect();
    
    // Testa rapidinho pra ver se a conexão tá OK.
    if (!await db.testConnection()) {
      // Se der ruim, avisa e para o programa.
      stderr.writeln('Falha no teste de conexão. Verifique as credenciais no app.dart.');
      return; 
    }
    
    // Se a conexão passou, a gente chama o menu principal pra rodar o programa!
    await app.menu(db); 
    
  } catch (e, st) {
    // === Deu Erro Inesperado (Fatal) ===
    // Se alguma coisa quebrar que a gente não esperava (tipo um erro geral),
    // a gente captura aqui, avisa e mostra o rastro do erro (Stack Trace).
    print('Erro fatal: $e');
    print(st); 
    
  } finally {
    // === Fim de Tudo ===
    // Isso aqui RODA SEMPRE, mesmo que tenha dado erro no meio do caminho.
    
    // A gente fecha a conexão do banco no final para não deixar nada aberto.
    await db.close();
  }
}