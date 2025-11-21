#include <WiFi.h> // Biblioteca para gerenciar a conexão Wi-Fi do ESP32
#include <FirebaseESP32.h> // Biblioteca para interagir com o Firebase Realtime Database

// === 1. Configurações de Rede ===
#define WIFI_SSID "SEU_WIFI" // <-- ALTERAR
#define WIFI_PASSWORD "SUA_SENHA_WIFI" // <-- ALTERAR

// === 2. Configurações do Firebase ===
#define FIREBASE_HOST "https://seu-projeto.firebaseio.com" // <-- VERIFICAR
#define FIREBASE_AUTH "SEU TOKEN" // <-- ALTERAR PARA O SEU TOKEN

// === 3. Caminhos no banco ===
// Caminho onde o peso simulado será enviado (escrita)
const String DATA_PATH = "/sensor/pesoAtual";
// Caminho do comando para iniciar a pesagem (leitura/escrita)
const String COMMAND_PATH = "/sensor/gerarPeso";

// Objetos Firebase
FirebaseData fbdo; // Objeto para armazenar dados de leitura/escrita e respostas do Firebase
FirebaseConfig config; // Objeto para configurações do Firebase (host, token)
FirebaseAuth auth; // Objeto para autenticação no Firebase

// Variáveis de simulação
float pesoAtual = 0.0; // Variável que armazena o peso simulado atual
bool simulandoPeso = false; // Flag que indica se a simulação de pesagem está ativa
unsigned long tempoInicioSimulacao = 0; // Marca o tempo (millis()) em que a simulação começou
const unsigned long DURACAO_SIMULACAO = 5000; // Duração da simulação de pesagem: 5000 ms = 5 segundos
const unsigned long INTERVALO_ENVIO = 500; // Intervalo entre envios de peso para o Firebase: 500 ms = 0,5 segundos
unsigned long ultimoEnvio = 0; // Marca o tempo (millis()) do último envio de peso

// === Funções auxiliares ===

// Função para conectar o ESP32 ao Wi-Fi
void connectWiFi() {
  Serial.print("Conectando-se a ");
  Serial.println(WIFI_SSID);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD); // Inicia a conexão

  int count = 0;
  // Tenta conectar por no máximo 10 segundos (20 * 500ms)
  while (WiFi.status() != WL_CONNECTED && count < 20) {
    delay(500);
    Serial.print(".");
    count++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\nWiFi conectado!");
    Serial.print("IP: ");
    Serial.println(WiFi.localIP()); // Exibe o IP
  } else {
    Serial.println("\nFalha na conexão WiFi!");
  }
}

// Função para configurar e iniciar a comunicação com o Firebase
void setupFirebase() {
  Serial.println("Conectando ao Firebase...");
  // Define o host e o token de autenticação
  config.host = FIREBASE_HOST;
  config.signer.tokens.legacy_token = FIREBASE_AUTH;
  
  // Inicia a comunicação com o Firebase
  Firebase.begin(&config, &auth);
  // Garante que a conexão com o Wi-Fi seja refeita em caso de perda
  Firebase.reconnectWiFi(true); 

  // Verifica se a conexão com o Firebase foi bem-sucedida
  if (!Firebase.ready()) {
    Serial.println("Erro ao conectar ao Firebase!");
    while (true) delay(100); // Trava o programa se não conseguir conectar
  }

  // Inicializa o comando no Firebase com 'false' (não está pesando)
  Firebase.setBool(fbdo, COMMAND_PATH.c_str(), false);
  // Inicializa o peso atual com '0.0'
  Firebase.setFloat(fbdo, DATA_PATH.c_str(), 0.0);
  Serial.println("Firebase pronto!");
}

// === Setup ===
void setup() {
  Serial.begin(115200); // Inicia a comunicação serial para debug
  delay(100);
  connectWiFi(); // Tenta conectar no Wi-Fi
  setupFirebase(); // Configura o Firebase
}

// === Funções de operação ===

// Função para iniciar a simulação de pesagem
void iniciarSimulacaoPeso() {
  simulandoPeso = true; // Ativa a flag de simulação
  tempoInicioSimulacao = millis(); // Marca o tempo de início

  // O randomSeed com esp_random() garante uma melhor aleatoriedade no ESP32
  randomSeed(esp_random()); 
  
  // Gera um valor aleatório de peso (simulação)
  // random(10000, 40000) gera inteiros entre 10000 e 39999
  // Dividido por 100.0, teremos floats entre 100.00 e 399.99 Kg
  pesoAtual = random(10000, 40000) / 100.0; 
  Serial.println(">>> PESAGEM INICIADA <<<");
}

// Função para monitorar e finalizar a simulação
void atualizarSimulacao() {
  // Se a simulação estiver ativa E o tempo limite tiver sido atingido
  if (simulandoPeso && millis() - tempoInicioSimulacao >= DURACAO_SIMULACAO) {
    simulandoPeso = false; // Desativa a simulação
    // Reseta o comando no Firebase para FALSE
    // Isso sinaliza para o lado do app/web que a pesagem acabou
    Firebase.setBool(fbdo, COMMAND_PATH.c_str(), false); 
    Serial.println(">>> PESAGEM FINALIZADA <<<");
  }
}

// === Loop Principal ===
void loop() {
  // Verifica se o Wi-Fi caiu. Se caiu, tenta reconectar.
  if (WiFi.status() != WL_CONNECTED) {
    connectWiFi();
    return; // Volta ao início do loop após a tentativa
  }

  // 1. **Verificar Comando Firebase**
  // Tenta ler o valor booleano do caminho de comando (`/sensor/gerarPeso`)
  if (Firebase.getBool(fbdo, COMMAND_PATH.c_str())) {
    // Se a leitura foi bem-sucedida (fbdo.boolData() é o valor lido)
    // E o valor lido é TRUE (comando de iniciar) E a simulação não está rodando
    if (fbdo.boolData() && !simulandoPeso) {
      iniciarSimulacaoPeso(); // Chama a função para iniciar a pesagem
    }
  }

  // 2. **Atualizar/Finalizar Simulação**
  atualizarSimulacao();

  // 3. **Enviar Dados (Se o intervalo permitir)**
  // Verifica se já passou o tempo do INTERVALO_ENVIO (0.5s)
  if (millis() - ultimoEnvio >= INTERVALO_ENVIO) {
    ultimoEnvio = millis(); // Atualiza a marca de tempo do último envio
    
    // Envia o valor do peso atual para o Firebase (`/sensor/pesoAtual`)
    if (Firebase.setFloat(fbdo, DATA_PATH.c_str(), pesoAtual)) {
      // Se o envio foi OK
      Serial.print("Peso enviado: ");
      Serial.print(pesoAtual, 2); // Imprime com 2 casas decimais
      Serial.println(" Kg");
    } else {
      // Se houve falha no envio
      Serial.print("Falha ao enviar: ");
      Serial.println(fbdo.errorReason()); // Exibe o erro do Firebase
    }
  }

  delay(50); // Pequeno delay para estabilidade do loop
}
