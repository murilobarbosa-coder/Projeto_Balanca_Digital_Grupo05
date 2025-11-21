import 'dart:io'; 
import 'package:mysql_client/mysql_client.dart'; // O pacote/biblioteca que nos permite conectar e interagir com o banco de dados.
import 'firebase_connector.dart'; // Importa as funções que criamos em outro arquivo para interagir com o Firebase e com o ESP32 (que gera o peso).
import 'credenciais.dart'; // Importa as credenciais centralizadas

// CONFIGURAÇÕES do mysql
// As constantes já estão importadas de 'credenciais.dart'

// Funções Auxiliares de Tratamento de Dados 
// Essas funções são necessárias para fazer a "ponte" entre os tipos de dados do Dart
// (como `int` e `double`) e os tipos que o driver do MySQL espera (como `BigInt`).
// O objetivo é evitar erros de incompatibilidade de tipos durante as consultas.

/// Normaliza parâmetros recursivamente: int -> BigInt
// O driver MySQL em Dart usa `BigInt` para números inteiros que serão enviados
// em consultas SQL (como IDs). Essa função garante que se passarmos um `int` do Dart,
// ele seja convertido corretamente para `BigInt` antes de ir para o driver.
dynamic _normalizeParams(dynamic value) {
  // Se for um `int` normal, converte para `BigInt`.
  if (value is int) return BigInt.from(value);
  // Se já for `BigInt`, retorna ele mesmo.
  if (value is BigInt) return value;
  // Se for um mapa (Map), percorre (recursivamente) cada valor para normalizar.
  if (value is Map) {
    final out = <String, dynamic>{};
    value.forEach((k, v) {
      // Converte a chave para String e normaliza o valor.
      out[k.toString()] = _normalizeParams(v);
    });
    return out;
  }
  // Se for uma lista (List), percorre (recursivamente) cada item para normalizar.
  if (value is List) {
    return value.map(_normalizeParams).toList();
  }
  // Para outros tipos (String, double, etc.), retorna o valor original.
  return value;
}

/// Obtém LAST_INSERT_ID() de forma segura e resiliente
// Depois de um `INSERT`, precisamos saber qual ID (chave primária) o banco acabou de gerar.
// O comando SQL `SELECT LAST_INSERT_ID()` faz isso.
Future<dynamic> _lastInsertId(MySQLConnection conn) async {
  // Executa a consulta.
  final r = await conn.execute('SELECT LAST_INSERT_ID() AS id');
  // Se não retornou linhas, significa que algo deu errado, retorna -1.
  if (r.numOfRows == 0) return -1;
  // Pega o valor da coluna 'id'.
  final val = r.rows.first.colByName('id');
  if (val == null) return -1;
  // Tenta converter o valor lido do banco para um `int` seguro do Dart.
  if (val is BigInt) return val.toInt(); // Se veio como BigInt, converte para int.
  if (val is int) return val; // Se veio como int, retorna ele.
  // Se veio como string ou outro, tenta fazer o parse (conversão), se falhar, retorna -1.
  return int.tryParse(val.toString()) ?? -1;
}

// Essa extensão parece ser um rascunho ou código incompleto. Não faz nada (corpo vazio).
extension on String {
  Future toInt() async {}
}

/// Verifica se affectedRows indica alterações (trata BigInt, int e outros)
// Após um `INSERT`, `UPDATE` ou `DELETE`, o banco diz quantas linhas foram afetadas (`affectedRows`).
// Esta função verifica se esse número é maior que zero (se houve alteração).
bool _hasAffectedRows(IResultSet res) {
  final ar = res.affectedRows;
  // Compara se o número de linhas afetadas (BigInt) é maior que zero.
  return ar > BigInt.zero;
}

/// Converte valor de id potencialmente BigInt/int/string para int seguro
// Wrapper para garantir que qualquer ID lido do banco (que pode vir em vários tipos)
// seja convertido para um `int` seguro e utilizável no código Dart.
int _toIntSafe(dynamic v) {
  if (v == null) return -1;
  if (v is BigInt) return v.toInt();
  if (v is int) return v;
  // Tentativa de parse para int, com fallback para -1.
  return int.tryParse(v.toString()) ?? -1;
}

// Wrapper para garantir que o valor do peso lido do banco vire um `double` no Dart.
double _toDoubleSafe(dynamic v) {
  if (v == null) return 0.0;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  if (v is BigInt) return v.toDouble(); // BigInt também pode ser peso, então convertemos.
  if (v is String) {
    // Tenta tratar strings que usam vírgula (',') como separador decimal.
    final s = v.trim();
    if (s.isEmpty) return 0.0;
    // Substitui a vírgula por ponto ('.') e tenta o parse.
    return double.tryParse(s.replaceAll(',', '.')) ?? 0.0;
  }
  // Tentativa geral de parse, com fallback para 0.0.
  return double.tryParse(v.toString().replaceAll(',', '.')) ?? 0.0;
}


// Funções Auxiliares de Entrada 
// Funções para facilitar a leitura de dados digitados pelo usuário no console,
// garantindo que o tipo de dado (String, int, double) seja o esperado.

String lerString(String prompt) {
  stdout.write(prompt); // Mostra a pergunta (prompt) na tela.
  String? input = stdin.readLineSync(); // Espera o usuário digitar e pressionar Enter.
  return input?.trim() ?? ''; // Limpa espaços em branco e retorna a string (ou vazia se for null).
}

int lerInt(String prompt) {
  String input = lerString(prompt);
  // Tenta converter a string para um inteiro. Se falhar, retorna -1 (inválido).
  return int.tryParse(input) ?? -1;
}

double lerDouble(String prompt) {
  String input = lerString(prompt);
  // Tenta converter para double, substituindo vírgula (se houver) por ponto antes. Se falhar, retorna -1.0.
  return double.tryParse(input.replaceAll(',', '.')) ?? -1.0;
}


// Classe Database (Conexão MySQL) 

class Database {
  late MySQLConnection conn; // O objeto que vai segurar a conexão ativa com o MySQL. O `late` diz que ele será inicializado antes de ser usado.

  // Abre a conexão com o banco de dados de forma assíncrona.
  Future<void> connect() async {
    stdout.writeln('Tentando conectar ao banco de dados...');
    try {
      // Cria o objeto de conexão usando as nossas constantes de configuração.
      conn = await MySQLConnection.createConnection(
        host: DB_HOST,
        port: DB_PORT,
        userName: DB_USER,
        password: DB_PASSWORD,
        databaseName: DB_NAME,
      );
      await conn.connect(); // De fato, estabelece a conexão.
      stdout.writeln('Conexão estabelecida com sucesso!');
    } catch (e) {
      stderr.writeln('ERRO ao conectar ao banco de dados: $e');
      rethrow; // Lança o erro para que a função principal (main) possa capturá-lo e parar a aplicação.
    }
  }

  // Fecha a conexão. É crucial fechar a conexão sempre que terminar,
  // por isso é chamado em um bloco `finally` no código principal.
  Future<void> close() async {
    stdout.writeln('Fechando conexão...');
    try {
      await conn.close();
    } catch (_) {} // Ignora erros no fechamento (ex: se tentarmos fechar uma conexão que já está fechada).
    stdout.writeln('Conexão fechada.');
  }

  // Faz um teste simples (SELECT 1) para garantir que o banco está online e respondendo.
  Future<bool> testConnection() async {
    try {
      final result = await conn.execute('SELECT 1 as v');
      return result.numOfRows > 0; // Se retornou pelo menos 1 linha, a conexão está OK.
    } catch (e, st) {
      stderr.writeln('Erro no teste de conexão: $e');
      stderr.writeln(st);
      return false;
    }
  }

  /// Wrapper que normaliza parâmetros (converte int -> BigInt) e chama conn.execute
  // Essa é a função que o nosso CRUD vai usar para executar todo SQL.
  // Ela é importante porque injeta a normalização dos parâmetros antes de enviar para o MySQL.
  Future<IResultSet> execute(String sql, [Map<String, dynamic>? params]) {
    // 1. Aplica a função de normalização nos parâmetros, se existirem.
    final normalized = params == null ? null : _normalizeParams(params) as Map<String, dynamic>;
    // 2. Chama a função `execute` real do cliente MySQL.
    return conn.execute(sql, normalized);
  }
}

// CRUD Responsável
// Classe que contém todas as operações CRUD (Create, Read, Update, Delete) para a tabela `responsavel`.

class ResponsavelCrud {
  final Database db; // Recebe a instância da conexão com o banco no construtor.
  ResponsavelCrud(this.db);

  Future<void> criar() async {
    String nome = lerString('Nome: ');
    // Menus para escolher o cargo, convertendo o número digitado para o texto que vai para o banco.
    print('Escolha o cargo: 1 - Gerente, 2 - Coordenador, 3 - Supervisor, 4 - Analista');
    int cargoNum = lerInt('Número do cargo: ');
    String cargo;
    switch (cargoNum) {
      case 1: cargo = 'Gerente'; break;
      case 2: cargo = 'Coordenador'; break;
      case 3: cargo = 'Supervisor'; break;
      case 4: cargo = 'Analista'; break;
      default: cargo = 'Indefinido'; break;
    }

    print('Escolha o setor: 1 - Vendas, 2 - Produção, 3 - Administrativo, 4 - Financeiro');
    int setorNum = lerInt('Número do setor: ');
    String setor;
    switch (setorNum) {
      case 1: setor = 'Vendas'; break;
      case 2: setor = 'Produção'; break;
      case 3: setor = 'Administrativo'; break;
      case 4: setor = 'Financeiro'; break;
      default: setor = 'Indefinido'; break;
    }

    String cpf = lerString('CPF: ');
    if (nome.isEmpty || cargo.isEmpty || setor.isEmpty || cpf.isEmpty) {
      print('Campos obrigatórios ausentes.');
      return;
    }

    // Executa o `INSERT`. Usamos **parâmetros nomeados** (`:nome`, `:cargo`, etc.)
    // em vez de concatenar strings, o que é fundamental para evitar **SQL Injection**.
    final res = await db.execute(
      'INSERT INTO responsavel (nome, cargo, setor, cpf) VALUES (:nome, :cargo, :setor, :cpf)',
      { 'nome': nome, 'cargo': cargo, 'setor': setor, 'cpf': cpf, },
    );
    // Verifica se o INSERT afetou alguma linha (se foi bem-sucedido).
    if (_hasAffectedRows(res)) {
      final id = await _lastInsertId(db.conn); // Pega o ID gerado.
      print('Responsável criado. ID=$id');
    } else {
      print('Falha ao criar responsável.');
    }
  }

  Future<void> listar() async {
    print('\n--- LISTA DE RESPONSÁVEIS ---');
    final res = await db.execute('SELECT * FROM responsavel');
    if (res.numOfRows == 0) {
      print('Nenhum responsável cadastrado.');
      return;
    }
    // Itera sobre o resultado da consulta (todas as linhas) e exibe.
    for (final row in res.rows) {
      // Usa `_toIntSafe` para garantir que o ID seja um `int` válido.
      final id = _toIntSafe(row.colByName('id_responsavel'));
      // `colByName` pega o valor da coluna pelo nome.
      final nome = row.colByName('nome')?.toString() ?? '';
      final cargo = row.colByName('cargo')?.toString() ?? '';
      final setor = row.colByName('setor')?.toString() ?? '';
      final cpf = row.colByName('cpf')?.toString() ?? '';
      print('id=$id, nome=$nome, cargo=$cargo, setor=$setor, cpf=$cpf');
    }
  }

  Future<void> editar() async {
    int id = lerInt('ID do responsável: ');
    if (id <= 0) return;
    // 1. Busca o registro atual para carregar os dados existentes (e checar se o ID existe).
    final r = await db.execute('SELECT * FROM responsavel WHERE id_responsavel = :id', {'id': id});
    if (r.numOfRows == 0) {
      print('Responsável não encontrado.');
      return;
    }
    final row = r.rows.first; // A primeira (e única) linha encontrada.

    // Pede novo nome. Se o usuário só apertar Enter, a string fica vazia.
    String nome = lerString('Novo nome (enter para manter): ');

    // 2. Lógica para cargo e setor:
    // Se o usuário digitar um número **inválido**, o `default` pega o valor **antigo** do banco.
    print('Escolha o novo cargo: 1 - Gerente, 2 - Coordenador, 3 - Supervisor, 4 - Analista');
    int cargoNum = lerInt('Número do cargo: ');
    String cargo;
    switch (cargoNum) {
      case 1: cargo = 'Gerente'; break;
      case 2: cargo = 'Coordenador'; break;
      case 3: cargo = 'Supervisor'; break;
      case 4: cargo = 'Analista'; break;
      // Se não digitou um número válido (ou -1), usa o valor atual do banco.
      default: cargo = row.colByName('cargo')?.toString() ?? 'Indefinido'; break; 
    }
    // ... lógica similar para Setor ...
    
    print('Escolha o novo setor: 1 - Vendas, 2 - Produção, 3 - Administrativo, 4 - Financeiro');
    int setorNum = lerInt('Número do setor: ');
    String setor;
    switch (setorNum) {
      case 1: setor = 'Vendas'; break;
      case 2: setor = 'Produção'; break;
      case 3: setor = 'Administrativo'; break;
      case 4: setor = 'Financeiro'; break;
      default: setor = row.colByName('setor')?.toString() ?? 'Indefinido'; break;
    }

    String cpf = lerString('Novo CPF (enter para manter): ');

    // 3. Monta o mapa de parâmetros. Se o novo nome/cpf estiver vazio, usa o valor antigo (lido na etapa 1).
    final params = {
      // Se `nome.isNotEmpty`, usa o novo nome; senão, usa o nome do banco.
      'nome': nome.isNotEmpty ? nome : row.colByName('nome')?.toString() ?? '', 
      'cargo': cargo, // Cargo e setor já contêm o novo ou o antigo (devido à lógica do switch/default).
      'setor': setor,
      'cpf': cpf.isNotEmpty ? cpf : row.colByName('cpf')?.toString() ?? '',
      'id': id,
    };

    // 4. Executa o `UPDATE` usando os parâmetros. O `WHERE id_responsavel = :id` é crucial.
    final res = await db.execute(
      'UPDATE responsavel SET nome = :nome, cargo = :cargo, setor = :setor, cpf = :cpf WHERE id_responsavel = :id',
      params,
    );
    if (_hasAffectedRows(res)) print('Responsável atualizado.');
    else print('Nenhuma alteração realizada.');
  }

  Future<void> excluir() async {
    int id = lerInt('ID do responsável: ');
    if (id <= 0) return;
    // Executa o `DELETE`.
    final res = await db.execute('DELETE FROM responsavel WHERE id_responsavel = :id', {'id': id});
    if (_hasAffectedRows(res)) print('Responsável excluído.');
    else print('Responsável não encontrado.');
  }
}

// CRUD Balança
// Classe idêntica ao CRUD Responsável, mas para a tabela `balanca`.

class BalancaCrud {
  final Database db;
  BalancaCrud(this.db);

  Future<void> criar() async {
    // Lógica para mapear a escolha do usuário (número) para o `status_balanca` (string).
    print('Escolha o status da balança: 1 - Funcionando, 2 - Em uso, 3 - Manutenção, 4 - Desativado');
    int statusNum = lerInt('Número do status: ');
    String status;
    switch (statusNum) {
      case 1: status = 'Funcionando'; break;
      case 2: status = 'Em uso'; break;
      case 3: status = 'Manutenção'; break;
      case 4: status = 'Desativado'; break;
      default: status = 'Indefinido'; break;
    }

    String descricao = lerString('Descrição: ');
    if (descricao.isEmpty) {
      print('Descrição é obrigatória.');
      return;
    }

    final res = await db.execute(
      'INSERT INTO balanca (status_balanca, descricao) VALUES (:status, :descricao)',
      {'status': status, 'descricao': descricao},
    );
    if (_hasAffectedRows(res)) {
      final id = await _lastInsertId(db.conn);
      print('Balança criada. ID=$id');
    } else {
      print('Falha ao criar balança.');
    }
  }

  Future<void> listar() async {
    print('\n--- LISTA DE BALANÇAS ---');
    final res = await db.execute('SELECT * FROM balanca');
    if (res.numOfRows == 0) {
      print('Nenhuma balança cadastrada.');
      return;
    }
    for (final row in res.rows) {
      final id = _toIntSafe(row.colByName('id_balanca'));
      final status = row.colByName('status_balanca')?.toString() ?? '';
      final descricao = row.colByName('descricao')?.toString() ?? '';
      print('id=$id, status=$status, descricao=$descricao');
    }
  }

  Future<void> editar() async {
    int id = lerInt('ID da balança: ');
    if (id <= 0) return;
    // 1. Busca o registro atual.
    final r = await db.execute('SELECT * FROM balanca WHERE id_balanca = :id', {'id': id});
    if (r.numOfRows == 0) {
      print('Balança não encontrada.');
      return;
    }
    final row = r.rows.first;
    
    print('Escolha o novo status da balança: 1 - Funcionando, 2 - Em uso, 3 - Manutenção, 4 - Desativado');
    int statusNum = lerInt('Número do status: ');

    String status;
    // 2. Lógica para manter o status antigo se o novo for inválido.
    switch (statusNum) {
      case 1: status = 'Funcionando'; break;
      case 2: status = 'Em uso'; break;
      case 3: status = 'Manutenção'; break;
      case 4: status = 'Desativado'; break;
      default: status = row.colByName('status_balanca')?.toString() ?? 'Indefinido'; break;
    }

    String descricao = lerString('Nova descrição (enter para manter): ');
    // 3. Monta parâmetros, usando a nova descrição ou a antiga.
    final params = {
      'status': status,
      'descricao': descricao.isNotEmpty ? descricao : row.colByName('descricao')?.toString() ?? '',
      'id': id,
    };

    // 4. Executa o UPDATE.
    final res = await db.execute(
      'UPDATE balanca SET status_balanca = :status, descricao = :descricao WHERE id_balanca = :id',
      params,
    );
    if (_hasAffectedRows(res)) print('Balança atualizada.');
    else print('Nenhuma alteração realizada.');
  }

  Future<void> excluir() async {
    int id = lerInt('ID da balança: ');
    if (id <= 0) return;
    final res = await db.execute('DELETE FROM balanca WHERE id_balanca = :id', {'id': id});
    if (_hasAffectedRows(res)) print('Balança excluída.');
    else print('Balança não encontrada.');
  }
}

// CRUD Pesagem (Onde o Firebase age)

class PesagemCrud {
  final Database db;
  PesagemCrud(this.db);

  // Função de regra de negócio: Define se o peso é 'Normal', 'Alerta' ou 'Critico'.
  String calcularStatus(double peso) {
    if (peso < 200) return 'Alerta'; // Abaixo de 200kg é Alerta.
    if (peso > 350) return 'Critico'; // Acima de 350kg é Crítico.
    return 'Normal'; // Entre 200kg e 350kg é Normal.
  }

  Future<void> criar() async {
    int responsavelId = lerInt('ID do responsável: ');
    int balancaId = lerInt('ID da balança: ');
    // Pega a data e hora atuais e formata para caber no campo DATETIME do MySQL (ex: 2025-11-19 12:07:49).
    String dataHora = DateTime.now().toString().substring(0, 19);

    if (responsavelId <= 0 || balancaId <= 0 || dataHora.isEmpty) {
      print('Dados inválidos.');
      return;
    }

    // 1. Manda o comando para o ESP32 começar a simulação (via Firebase).
    // A função `enviarComandoGerarPeso()` deve escrever um valor no Firebase que o ESP32 (ou a simulação) lê.
    final comandoEnviado = await enviarComandoGerarPeso();
    if (!comandoEnviado) {
      print('Falha ao enviar comando ao ESP32.');
      return;
    }

    // 2. Fica esperando e lendo o peso do Firebase (polling).
    double peso = 0.0;
    const int maxTentativas = 20; //  Máximo de 20 segundos para tentar a leitura.
    print('Iniciando leitura do peso...');
    for (int t = 0; t < maxTentativas; t++) {
      await Future.delayed(Duration(seconds: 1)); // Espera 1 segundo.
      peso = await lerPeso(); // Lê o valor que foi atualizado no Firebase/simulação.
      if (peso > 0.0) break; // Se o peso é válido (> 0.0), para o loop.
    }

    print('Peso final obtido: ${peso.toStringAsFixed(2)} Kg');

    if (peso <= 0.0) {
      print('Não foi possível obter o peso > 0.0.');
      return;
    }

    // 3. Processa o status do peso usando a regra de negócio.
    String status = calcularStatus(peso);

    // 4. Salva no banco de dados.
    final res = await db.execute(
      '''
      INSERT INTO pesagem (valor_pesagem, data_hora, status_peso, responsavel_id_responsavel, balanca_id_balanca)
      VALUES (:valor, :dataHora, :status, :respId, :balId)
      ''',
      {
        'valor': peso,
        'dataHora': dataHora,
        'status': status,
        'respId': responsavelId,
        'balId': balancaId,
      },
    );

    if (_hasAffectedRows(res)) {
      final id = await _lastInsertId(db.conn);
      print('Pesagem registrada. ID=$id');
    } else {
      print('Falha ao registrar pesagem. (Verifique se há restrições no DB)'); // Ex: Foreign Key Constraint.
    }
  }

  Future<void> listar() async {
    print('\n--- LISTA DE PESAGENS ---');
    // Fazemos um `JOIN` nas tabelas `responsavel` e `balanca` para
    // trazer os nomes (`r.nome`, `b.descricao`) em vez de apenas os IDs.
    final res = await db.execute('''
      SELECT p.id_pesagem, p.valor_pesagem, p.data_hora, p.status_peso,
             r.nome AS responsavel_nome, b.descricao AS balanca_descricao
      FROM pesagem p
      JOIN responsavel r ON p.responsavel_id_responsavel = r.id_responsavel
      JOIN balanca b ON p.balanca_id_balanca = b.id_balanca
      ORDER BY p.data_hora DESC 
    '''); // Ordena da mais nova para a mais antiga.
    if (res.numOfRows == 0) {
      print('Nenhuma pesagem registrada.');
      return;
    }
    for (final row in res.rows) {
      final id = _toIntSafe(row.colByName('id_pesagem'));
      final rawValor = row.colByName('valor_pesagem');
      final valor = _toDoubleSafe(rawValor); // Garante que o valor lido é um double.
      final data = row.colByName('data_hora')?.toString() ?? '';
      final status = row.colByName('status_peso')?.toString() ?? '';
      // Acessamos os nomes/descrições que foram criados no `SELECT` com AS.
      final responsavel = row.colByName('responsavel_nome')?.toString() ?? '';
      final balanca = row.colByName('balanca_descricao')?.toString() ?? '';
      print('id=$id, valor=${valor.toStringAsFixed(2)} Kg, data=$data, status=$status, responsavel=$responsavel, balança=$balanca');
    }
  }

  Future<void> editar() async {
    int id = lerInt('ID da pesagem: ');
    if (id <= 0) return;
    // 1. Checa se a pesagem existe.
    final r = await db.execute('SELECT * FROM pesagem WHERE id_pesagem = :id', {'id': id});
    if (r.numOfRows == 0) {
      print('Pesagem não encontrada.');
      return;
    };

    String dataHora = DateTime.now().toString().substring(0, 19);

    // 2. Repete a lógica de iniciar e ler o peso via Firebase.
    // Na edição, o que fazemos é simular uma **nova pesagem** para atualizar o valor, data e status.
    final comandoEnviado = await enviarComandoGerarPeso();
    if (!comandoEnviado) {
      print('Falha ao enviar comando ao ESP32.');
      return;
    }

    double peso = 0.0;
    const int maxTentativas = 20; 
    print('Iniciando leitura do peso...');
    for (int t = 0; t < maxTentativas; t++) {
      await Future.delayed(Duration(seconds: 1));
      peso = await lerPeso();
      if (peso > 0.0) break;
    }
    
    print('Peso final obtido para edição: ${peso.toStringAsFixed(2)} Kg');

    if (peso <= 0.0) {
      print('Falha ao obter o peso.');
      return;
    }

    String status = calcularStatus(peso);

    final params = {
      'peso': peso,
      'dataHora': dataHora,
      'status': status,
      'id': id,
    };

    // 3. Executa o UPDATE, mas **apenas** para o valor, data/hora e status.
    // O responsável e a balança permanecem os mesmos (não são editáveis nesta função).
    final res = await db.execute(
      '''
      UPDATE pesagem 
      SET valor_pesagem = :peso, data_hora = :dataHora, status_peso = :status
      WHERE id_pesagem = :id
      ''',
      params,
    );

    if (_hasAffectedRows(res)) {
      print('Pesagem atualizada.');
    } else {
      print('Nenhuma alteração realizada.');
    }
  }

  Future<void> excluir() async {
    int id = lerInt('ID da pesagem a excluir: ');
    if (id <= 0) {
      print('ID inválido.');
      return;
    }
    final res = await db.execute('DELETE FROM pesagem WHERE id_pesagem = :id', {'id': id});
    if (_hasAffectedRows(res)) print('Pesagem excluída com sucesso.');
    else print('Pesagem não encontrada.');
  }
}

// --- Menu Principal (O que o usuário vê) ---

Future<void> menu(Database db) async {
  // Inicializa as classes de CRUD, passando a conexão com o banco (`db`) para elas.
  // Isso permite que todas as classes de CRUD usem a mesma conexão.
  final responsavel = ResponsavelCrud(db);
  final balanca = BalancaCrud(db);
  final pesagem = PesagemCrud(db);

  void showMenu() {
    print('\n================ SISTEMA ================');
    print('RESPONSÁVEL:  1.Criar  2.Listar  3.Editar  4.Excluir');
    print('BALANÇA:      5.Criar  6.Listar  7.Editar  8.Excluir');
    print('PESAGEM:      9.Criar 10.Listar 11.Editar 12.Excluir');
    print('0.Sair');
    stdout.write('Escolha: ');
  }

  while (true) { // Loop infinito para manter o menu ativo até o usuário escolher sair (opção 0).
    showMenu();
    final opt = stdin.readLineSync(); // Lê a opção digitada.
    if (opt == null) return; // Se o input for nulo (ex: terminal fechado), sai.
    final o = opt.trim();
    if (o.isEmpty) continue; // Se digitou vazio, volta para o topo do loop e mostra o menu de novo.
    if (o == '0') {
      print('Saindo.');
      return; // Sai da função 'menu' (e o programa termina no `main`).
    }
    
    try {
      // O `switch` direciona a opção digitada para a função CRUD correta, chamando o método assíncrono.
      switch (o) {
        case '1': await responsavel.criar(); break;
        case '2': await responsavel.listar(); break;
        case '3': await responsavel.editar(); break;
        case '4': await responsavel.excluir(); break;
        case '5': await balanca.criar(); break;
        case '6': await balanca.listar(); break;
        case '7': await balanca.editar(); break;
        case '8': await balanca.excluir(); break;
        case '9': await pesagem.criar(); break;
        case '10': await pesagem.listar(); break;
        case '11': await pesagem.editar(); break;
        case '12': await pesagem.excluir(); break;
        default: print('Opção inválida.');
      }
    } catch (e, st) {
      // Bloco para capturar e mostrar erros que ocorreram DURANTE a execução de um CRUD
      // (como um erro de SQL, ou falha de conexão que não foi capturada no `connect`).
      print('Erro: $e');
      print(st);
    }
  }
}