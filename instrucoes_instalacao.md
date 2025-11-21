# Instruções de Instalação e Configuração  
### Projeto: Balança Digital Inteligente (PI – Grupo 05)

Este documento descreve, de forma profissional e detalhada, o processo completo para instalação, configuração e execução do sistema **Balança Digital Inteligente**, composto por:

- Aplicação Dart (console)
- Microcontrolador ESP32
- Banco de Dados MySQL
- Firebase Realtime Database

O objetivo é permitir que qualquer usuário consiga executar o projeto corretamente, mesmo sem conhecimento prévio no ambiente.

---

## 1. Requisitos do Ambiente

Antes de iniciar, certifique-se de possuir:

### ► Banco e Backend
- **MySQL Server** (8.x recomendado)
- Cliente opcional: **MySQL Workbench**

### ► Aplicação em Dart
- **Dart SDK** (versão atual)
- Editor recomendado: **VS Code**

### ► Ambiente do ESP32
- **Arduino IDE** (com suporte ESP32 instalado)
  ou
- **VSCode + PlatformIO**

### ► Serviços em Nuvem
- Conta no **Firebase**
- Módulo **Realtime Database** habilitado

---

## 2. Configuração do MySQL

### 2.1 Criar banco e tabelas

No MySQL Workbench ou terminal, execute:

```sql
CREATE DATABASE IF NOT EXISTS bancod
  DEFAULT CHARACTER SET = utf8mb4
  DEFAULT COLLATE = utf8mb4_unicode_ci;
USE bancod;

SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS pesagem;
DROP TABLE IF EXISTS balanca;
DROP TABLE IF EXISTS responsavel;

CREATE TABLE responsavel (
  id_responsavel INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
  nome VARCHAR(100) NOT NULL,
  cargo VARCHAR(60) NOT NULL,
  setor VARCHAR(60) NOT NULL,
  cpf VARCHAR(20) NOT NULL,
  UNIQUE KEY ux_responsavel_cpf (cpf)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE balanca (
  id_balanca INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
  status_balanca ENUM('funcionando','em uso','manutencao','desativado') NOT NULL,
  descricao VARCHAR(100) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE pesagem (
  id_pesagem INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
  valor_pesagem DECIMAL(10,3) NOT NULL,
  data_hora DATETIME NOT NULL,
  status_peso ENUM('Normal','Alerta','Critico') NOT NULL,
  responsavel_id_responsavel INT NOT NULL,
  balanca_id_balanca INT NOT NULL,
  CONSTRAINT fk_pesagem_responsavel FOREIGN KEY (responsavel_id_responsavel)
    REFERENCES responsavel(id_responsavel)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT fk_pesagem_balanca FOREIGN KEY (balanca_id_balanca)
    REFERENCES balanca(id_balanca)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  INDEX ix_pesagem_datahora (data_hora),
  INDEX ix_pesagem_responsavel (responsavel_id_responsavel),
  INDEX ix_pesagem_balanca (balanca_id_balanca)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SET FOREIGN_KEY_CHECKS = 1;
```

Após isso, o banco estará pronto para uso pela aplicação Dart.

---

## 3. Configuração do Firebase Realtime Database

### 3.1 Criar projeto no Firebase

1. Acesse: https://console.firebase.google.com  
2. Clique em **Adicionar Projeto**  
3. Preencha as informações básicas  
4. Após criado, vá em **Build → Realtime Database**  
5. Clique em **Criar Banco de Dados**  
6. Selecione **Modo de Teste (Test Mode)** 

### 3.2 Estrutura necessária no banco

Crie manualmente os nós iniciais (opcional — a aplicação e o ESP32 também criam):

```
/sensor
    gerarPeso    (boolean)
    pesoAtual    (float)
```

### 3.3 Dados necessários para integração

Você precisará coletar:

- **URL base do Realtime Database**  
  Exemplo:  
  ```
  https://seu-projeto-default-rtdb.firebaseio.com
  ```

- **Database Secret / Token**  
  Acesse:  
  *Project Settings → Service Accounts → Database Secrets*

Esses dados serão colocados no `credenciais.dart`.

---

## 4. Configuração da Aplicação Dart

### 4.1 Instalar dependências

Dentro da pasta da aplicação:

```
dart pub get
```

### 4.2 Criar arquivo obrigatória de credenciais

Crie:

```
dart_app/lib/credenciais.dart
```

Conteúdo base:

```dart
// Firebase
const String FIREBASE_URL = 'https://seu-projeto.firebaseio.com';
const String FIREBASE_AUTH = 'SEU_TOKEN';
const String PATH_COMANDO = '/sensor/gerarPeso';
const String PATH_PESO = '/sensor/pesoAtual';

// MySQL
const String DB_HOST = 'localhost';
const int DB_PORT = 3306;
const String DB_USER = 'root';
const String DB_PASSWORD = 'sua_senha';
const String DB_NAME = 'bancod';
```

### 4.3 Executar a aplicação

```
dart run codigo_main.dart
```

A aplicação:

1. Detecta usuários já cadastrados  
2. Envia comando para iniciar pesagem  
3. Lê peso do Firebase  
4. Aplica regras de negócio  
5. Registra tudo no MySQL  

---

## 5. Configuração do ESP32

### 5.1 Abrir o código

Abra o arquivo:

```
esp32/balanca_sim.ino
```

### 5.2 Inserir credenciais

Localize as linhas:

```cpp
#define WIFI_SSID "SEU_WIFI"
#define WIFI_PASSWORD "SUA_SENHA_WIFI"

#define FIREBASE_HOST "https://seu-projeto.firebaseio.com"
#define FIREBASE_AUTH "SEU_TOKEN"
```

Preencha com seus dados reais:

- Rede Wi-Fi
- Firebase Host
- Token (Database Secret)

### 5.3 Compilação e Upload

1. Abra Arduino IDE  
2. Vá em **Ferramentas → Placa → ESP32 Dev Module**  
3. Conecte o cabo USB  
4. Selecione a porta correta  
5. Compile e envie (Upload)

### 5.4 Funcionamento

O ESP32:

- Lê continuamente `/sensor/gerarPeso`
- Se receber TRUE:
  - Inicia simulação (duração 5s)
  - Envia peso a cada 500ms
- Ao final, zera o comando: `/sensor/gerarPeso = false`

---

## 6. Execução Completa do Sistema

Após configurar **MySQL**, **Firebase**, **Dart** e **ESP32**:

1. **Suba o ESP32** e deixe-o conectado ao Wi-Fi  
2. **Execute a aplicação Dart**  
3. No menu, escolha "Realizar Pesagem"  
4. O Dart envia comando → Firebase  
5. O ESP32 simula peso → Firebase  
6. O Dart lê o peso e salva tudo no MySQL

O sistema estará funcionando integralmente.

---

## 7. Conclusão

Seguindo este documento, qualquer usuário consegue instalar todo o ambiente, configurar os serviços externos e executar o sistema completo de pesagem digital usando ESP32, Firebase e Dart com MySQL.

Este documento serve como guia técnico oficial do projeto.
