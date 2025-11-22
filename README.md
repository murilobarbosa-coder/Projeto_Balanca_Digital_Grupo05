## Balança Digital Inteligente (PI - Grupo 05)

Este projeto implementa um sistema de Balança Digital Inteligente que simula a comunicação entre um dispositivo *ESP32* e uma *Aplicação Desktop/Console em Dart* utilizando o *Firebase Realtime Database* como intermediário (Broker/Mensageria).

A aplicação em Dart/Flutter (Console) gerencia o cadastro de Responsáveis e Balanças em um banco de dados *MySQL* e orquestra o processo de pesagem, enviando comandos ao ESP32 e lendo o resultado para registro final.

## Arquitetura e Fluxo de Dados

O sistema opera em três camadas principais, conectadas via rede:

1.  *ESP32 (Simulação):* Simula a balança, gera um peso aleatório e o envia para o Firebase.
2.  *Firebase Realtime Database:* Atua como um canal de comunicação em tempo real.
    * Recebe o *comando* da aplicação Dart para iniciar a pesagem (/sensor/gerarPeso).
    * Recebe o *peso atual* enviado pelo ESP32 (/sensor/pesoAtual).
3.  *Aplicação Dart (Console):*
    * Executa operações *CRUD* (MySQL) para Responsável, Balança e Pesagem.
    * *Inicia a pesagem* enviando o comando TRUE ao Firebase (dispara o ESP32).
    * *Lê o peso* do Firebase e o salva no MySQL.

---

## Instalação e Configuração

Para executar este projeto, você precisará configurar o ambiente de desenvolvimento e as credenciais de banco de dados e Firebase.

### Pré-requisitos

* *Dart SDK* (para rodar a aplicação Console)
* *MySQL Server* (ou MariaDB) rodando localmente (configurado como localhost:3306).
* *Acesso ao Firebase Realtime Database* (Host e Token).
* *Arduino IDE / VSCode PlatformIO* (para o código ESP32, se for rodar no hardware real).

### Configuração da Aplicação Dart (Console)

1.  *Dependências:* Certifique-se de que as dependências (`mysql_client` e `http`) estão instaladas (geralmente via `pubspec.yaml` e `dart pub get`).

2.  *Credenciais MySQL e Firebase:*  
    As credenciais foram separadas no arquivo `lib/credenciais.dart` para facilitar a manutenção e segurança.  
    Este arquivo está listado no `.gitignore` e **não será versionado no GitHub**, protegendo suas informações sensíveis.

    Exemplo de estrutura do arquivo:

    ```dart
    // lib/credenciais.dart

    // Firebase
    const String FIREBASE_URL = 'https://seu-projeto.firebaseio.com'; // <-- ALTERAR
    const String PATH_COMANDO = '/sensor/gerarPeso';
    const String PATH_PESO = '/sensor/pesoAtual';

    // MySQL
    const String DB_HOST = 'localhost';
    const int DB_PORT = 3306;
    const String DB_USER = 'seu_usuario'; // <-- ALTERAR
    const String DB_PASSWORD = 'sua_senha'; // <-- ALTERAR
    const String DB_NAME = 'bancod'; // <-- ALTERAR
    ```

3.  *Importação nos arquivos principais:*  
    Os arquivos `app.dart` e `firebase_connector.dart` já estão configurados para importar essas credenciais automaticamente.

### Configuração do Código ESP32 (Simulação)

O código ESP32 (simulação da balança) contém as credenciais de Wi-Fi e Firebase. *Atenção: Estas credenciais devem ser alteradas.*

1.  *Rede Wi-Fi:* (Fonte 465, 466)
    ```cpp
    #define WIFI_SSID "SEU_WIFI" // <-- ALTERAR
    #define WIFI_PASSWORD "SUA_SENHA_WIFI" // <-- ALTERAR
    ```

2.  *Credenciais Firebase:* (Fonte 468)
    ```cpp
    #define FIREBASE_HOST "https://seu-projeto.firebaseio.com" // <-- VERIFICAR
    #define FIREBASE_AUTH "SEU TOKEN" // <-- ALTERAR PARA O SEU TOKEN
    ```

### Execução

1.  *Banco de Dados MySQL:* Crie um schema `bancod` e as tabelas `responsavel`, `balanca`, e `pesagem` (o schema 'sql' está localizado em um arquivo separado *bancod*).
2.  *ESP32:* Compile e faça o upload do código para o seu ESP32 (código do Arduino IDE *balanca_pi* também está depositado separadamente).
3.  *Aplicação Dart:* Execute o código principal:
    ```bash
    dart run codigo_main.dart
    ```

---

## Detalhes da Implementação (Código Comentado)

O projeto é modularizado em três arquivos principais:

### 1. Código ESP32 (Simulação da Balança)

* *Comunicação:* Usa as bibliotecas WiFi.h e FirebaseESP32.h.
* *Caminhos Firebase:* Envia o peso atual para /sensor/pesoAtual e monitora o comando para iniciar a pesagem em /sensor/gerarPeso.
* *Fluxo de Pesagem (Função loop):*
    * Monitora o comando em /sensor/gerarPeso. Se o valor for TRUE e a simulação não estiver ativa, inicia a pesagem.
    * A função iniciarSimulacaoPeso() gera um valor de peso aleatório entre 100.00 Kg e 399.99 Kg.
    * O peso é enviado a cada 500 ms (0,5s) para o Firebase (INTERVALO_ENVIO).
    * A pesagem dura 5 segundos (DURACAO_SIMULACAO) e, ao final, o comando /sensor/gerarPeso é resetado para FALSE.

### 2. Código firebase_connector.dart

* *Abstração HTTP:* Contém funções Dart que usam o pacote http para interagir com a *API REST do Firebase*.
* *enviarComandoGerarPeso():* Usa o método *HTTP PUT* para escrever o valor true no caminho PATH_COMANDO (/sensor/gerarPeso).
* *lerPeso():* Usa o método *HTTP GET* para ler o valor atual do PATH_PESO (/sensor/pesoAtual).

### 3. Código app.dart (MySQL e CRUD)

* *Database Class:* Gerencia a conexão com o MySQL usando mysql_client. Inclui um wrapper (execute) que normaliza os parâmetros (converte int para BigInt) para evitar erros com o driver MySQL.
* *PesagemCrud (Criação):*
    * Chama enviarComandoGerarPeso() para iniciar o ciclo.
    * Faz um polling (loop de espera) por até 20 segundos, lendo o peso do Firebase (via lerPeso()) a cada 1 segundo até obter um valor válido (> 0.0).
    * Aplica a regra de negócio calcularStatus (Alerta < 200kg, Crítico > 350kg, Normal entre 200-350kg).
    * Salva o registro final na tabela pesagem no MySQL.
* *ResponsavelCrud / BalancaCrud:* Implementa todas as operações CRUD (criar, listar, editar, excluir) para as respectivas tabelas, usando *parâmetros nomeados* no SQL para prevenir SQL Injection.

---

## Membros do Grupo

* *Pedro Ignácio de Oliveira Bortolon* (RA: 25000137)
* *Luís Felipe Coelho* (RA: 25001003)
* *Murilo Colli Barbosa* (RA: 25000458)
* *Pollyana Caso* (RA: 25001334)
* *Júlia Gabrieli Beraldo* (RA: 25002215)

---

## Licença

Este projeto está licenciado sob a *Licença MIT*. Para detalhes completos, consulte o arquivo *LICENSE* na raiz deste repositório.
