-- Cria banco e seleciona
CREATE DATABASE IF NOT EXISTS bancod
  DEFAULT CHARACTER SET = utf8mb4
  DEFAULT COLLATE = utf8mb4_unicode_ci;
USE bancod;

-- Desativar checagem temporariamente para recriar tabelas
SET FOREIGN_KEY_CHECKS = 0;

-- Remover tabelas antigas na ordem segura
DROP TABLE IF EXISTS pesagem;
DROP TABLE IF EXISTS balanca;
DROP TABLE IF EXISTS responsavel;

-- Tabela responsavel
CREATE TABLE responsavel (
  id_responsavel INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
  nome VARCHAR(100) NOT NULL,
  cargo VARCHAR(60) NOT NULL,
  setor VARCHAR(60) NOT NULL,
  cpf VARCHAR(20) NOT NULL,
  UNIQUE KEY ux_responsavel_cpf (cpf)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Tabela balanca
CREATE TABLE balanca (
  id_balanca INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
  status_balanca ENUM('funcionando','em uso','manutencao','desativado') NOT NULL,
  descricao VARCHAR(100) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Tabela pesagem que referencia responsavel e balanca por id
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

-- Reativar checagem de FKs
SET FOREIGN_KEY_CHECKS = 1;

-- Inserir dados fictícios
INSERT INTO responsavel (nome, cargo, setor, cpf) VALUES
('Responsavel 01', 'Tecnica', 'Manutencao', '30330330330'),
('Responsavel 02', 'Supervisor', 'Producao', '40440440440'),
('Responsavel 03', 'Analista', 'Qualidade', '50550550550');

INSERT INTO balanca (status_balanca, descricao) VALUES
('funcionando','Balanca 01'),
('em uso','Balanca 02'),
('manutencao','Balanca 03');

INSERT INTO pesagem (valor_pesagem, data_hora, status_peso, responsavel_id_responsavel, balanca_id_balanca) VALUES
(314.300, '2023-01-05 08:12:34', 'Normal', 1, 1),
(110.000, '2023-01-12 09:05:11', 'Critico', 2, 2),
(205.000, '2024-01-23 10:22:45', 'Alerta', 3, 3);

SELECT
  p.id_pesagem,
  p.valor_pesagem,
  p.data_hora,
  p.status_peso,
  p.responsavel_id_responsavel,
  r.nome AS responsavel_nome,
  p.balanca_id_balanca,
  b.descricao AS balanca_descricao,
  b.status_balanca
FROM pesagem p
JOIN responsavel r ON p.responsavel_id_responsavel = r.id_responsavel
JOIN balanca b ON p.balanca_id_balanca = b.id_balanca
ORDER BY p.data_hora DESC;

-- Tabela pesagem
select * from pesagem;
