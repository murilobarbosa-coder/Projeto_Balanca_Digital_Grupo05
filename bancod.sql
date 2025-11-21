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

-- Inserir 10 responsaveis
INSERT INTO responsavel (nome, cargo, setor, cpf) VALUES
('Bruna Santos', 'Tecnica', 'Manutencao', '30330330330'),
('Diego Lima', 'Supervisor', 'Producao', '40440440440'),
('Camila Ribeiro', 'Analista', 'Qualidade', '50550550550'),
('Felipe Santos', 'Coordenador', 'Logistica', '60660660660'),
('Isabela Costa', 'Tecnica', 'Manutencao', '70770770770'),
('Gustavo Ferreira', 'Supervisor', 'Producao', '80880880880'),
('Marcela Alves', 'Analista', 'Qualidade', '90990990990'),
('Renato Martins', 'Coordenador', 'Logistica', '11111111211'),
('Sofia Almeida', 'Tecnica', 'Manutencao', '22222222322'),
('Vinicius Rocha', 'Supervisor', 'Producao', '33333333433');

-- Inserir 10 balancas
INSERT INTO balanca (status_balanca, descricao) VALUES
('funcionando','Balanca 01'),
('em uso','Balanca 02'),
('manutencao','Balanca 03'),
('desativado','Balanca 04'),
('funcionando','Balanca 05'),
('em uso','Balanca 06'),
('manutencao','Balanca 07'),
('desativado','Balanca 08'),
('funcionando','Balanca 09'),
('em uso','Balanca 10');

-- Inserir 200 pesagens (valor_pesagem, data_hora, status_peso, responsavel_id_responsavel, balanca_id_balanca)
INSERT INTO pesagem (valor_pesagem, data_hora, status_peso, responsavel_id_responsavel, balanca_id_balanca) VALUES
(265.300, '2023-01-05 08:12:34', 'Normal', 1, 1),
(270.000, '2023-01-12 09:05:11', 'Normal', 2, 2),
(275.000, '2023-01-23 10:22:45', 'Alerta', 3, 3),
(280.500, '2023-02-02 07:50:02', 'Normal', 4, 4),
(285.000, '2023-02-14 11:15:19', 'Critico', 5, 5),
(290.200, '2023-02-28 13:40:55', 'Normal', 6, 6),
(295.000, '2023-03-03 16:05:07', 'Normal', 7, 7),
(260.000, '2023-03-11 12:30:22', 'Normal', 8, 8),
(266.000, '2023-03-19 14:45:33', 'Normal', 9, 9),
(270.300, '2023-03-27 18:20:10', 'Alerta', 10, 10),
(267.450, '2023-04-04 08:03:50', 'Normal', 1, 1),
(271.120, '2023-04-09 09:44:12', 'Normal', 2, 2),
(276.800, '2023-04-15 10:55:01', 'Alerta', 3, 3),
(281.250, '2023-04-21 07:22:18', 'Normal', 4, 4),
(286.900, '2023-04-29 11:11:11', 'Critico', 5, 5),
(291.600, '2023-05-06 13:33:33', 'Normal', 6, 6),
(294.750, '2023-05-12 16:44:44', 'Normal', 7, 7),
(262.100, '2023-05-18 12:12:12', 'Normal', 8, 8),
(267.900, '2023-05-25 14:14:14', 'Normal', 9, 9),
(271.800, '2023-05-30 18:18:18', 'Alerta', 10, 10),
(268.300, '2023-06-02 08:08:08', 'Normal', 1, 1),
(272.500, '2023-06-10 09:09:09', 'Normal', 2, 2),
(277.200, '2023-06-18 10:10:10', 'Alerta', 3, 3),
(282.700, '2023-06-25 07:07:07', 'Normal', 4, 4),
(287.100, '2023-06-30 11:11:11', 'Critico', 5, 5),
(292.450, '2023-07-04 13:13:13', 'Normal', 6, 6),
(296.000, '2023-07-12 16:16:16', 'Normal', 7, 7),
(263.500, '2023-07-20 12:12:12', 'Normal', 8, 8),
(268.250, '2023-07-28 14:14:14', 'Normal', 9, 9),
(272.900, '2023-08-03 18:18:18', 'Alerta', 10, 10),
(269.100, '2023-08-11 08:30:30', 'Normal', 1, 1),
(273.300, '2023-08-19 09:40:40', 'Normal', 2, 2),
(278.600, '2023-08-27 10:50:50', 'Alerta', 3, 3),
(283.200, '2023-09-02 07:20:20', 'Normal', 4, 4),
(288.700, '2023-09-10 11:05:05', 'Critico', 5, 5),
(293.100, '2023-09-18 13:25:25', 'Normal', 6, 6),
(297.450, '2023-09-26 16:35:35', 'Normal', 7, 7),
(264.000, '2023-10-03 12:00:00', 'Normal', 8, 8),
(269.800, '2023-10-11 14:22:22', 'Normal', 9, 9),
(273.600, '2023-10-19 18:45:45', 'Alerta', 10, 10),
(270.250, '2023-10-27 08:08:08', 'Normal', 1, 1),
(274.900, '2023-11-04 09:09:09', 'Normal', 2, 2),
(279.300, '2023-11-12 10:10:10', 'Alerta', 3, 3),
(284.800, '2023-11-20 07:07:07', 'Normal', 4, 4),
(289.200, '2023-11-28 11:11:11', 'Critico', 5, 5),
(294.600, '2023-12-05 13:13:13', 'Normal', 6, 6),
(298.000, '2023-12-13 16:16:16', 'Normal', 7, 7),
(265.250, '2023-12-21 12:12:12', 'Normal', 8, 8),
(270.400, '2023-12-29 14:14:14', 'Normal', 9, 9),
(274.100, '2023-12-31 23:59:59', 'Alerta', 10, 10),
(266.700, '2024-01-03 08:05:05', 'Normal', 1, 1),
(271.900, '2024-01-11 09:15:15', 'Normal', 2, 2),
(276.400, '2024-01-19 10:25:25', 'Alerta', 3, 3),
(281.900, '2024-01-27 07:35:35', 'Normal', 4, 4),
(286.300, '2024-02-04 11:45:45', 'Critico', 5, 5),
(291.750, '2024-02-12 13:55:55', 'Normal', 6, 6),
(295.200, '2024-02-20 16:05:05', 'Normal', 7, 7),
(262.900, '2024-02-28 12:12:12', 'Normal', 8, 8),
(268.600, '2024-03-07 14:14:14', 'Normal', 9, 9),
(273.000, '2024-03-15 18:18:18', 'Alerta', 10, 10),
(267.800, '2024-03-23 08:08:08', 'Normal', 1, 1),
(272.400, '2024-03-31 09:09:09', 'Normal', 2, 2),
(277.900, '2024-04-08 10:10:10', 'Alerta', 3, 3),
(283.300, '2024-04-16 07:07:07', 'Normal', 4, 4),
(288.000, '2024-04-24 11:11:11', 'Critico', 5, 5),
(293.250, '2024-05-02 13:13:13', 'Normal', 6, 6),
(297.600, '2024-05-10 16:16:16', 'Normal', 7, 7),
(263.100, '2024-05-18 12:12:12', 'Normal', 8, 8),
(269.200, '2024-05-26 14:14:14', 'Normal', 9, 9),
(274.000, '2024-06-03 18:18:18', 'Alerta', 10, 10),
(268.900, '2024-06-11 08:30:30', 'Normal', 1, 1),
(273.700, '2024-06-19 09:40:40', 'Normal', 2, 2),
(278.100, '2024-06-27 10:50:50', 'Alerta', 3, 3),
(283.800, '2024-07-05 07:20:20', 'Normal', 4, 4),
(289.500, '2024-07-13 11:05:05', 'Critico', 5, 5),
(294.200, '2024-07-21 13:25:25', 'Normal', 6, 6),
(298.300, '2024-07-29 16:35:35', 'Normal', 7, 7),
(264.400, '2024-08-06 12:00:00', 'Normal', 8, 8),
(270.100, '2024-08-14 14:22:22', 'Normal', 9, 9),
(275.200, '2024-08-22 18:45:45', 'Alerta', 10, 10),
(269.500, '2024-08-30 08:08:08', 'Normal', 1, 1),
(274.000, '2024-09-07 09:09:09', 'Normal', 2, 2),
(279.700, '2024-09-15 10:10:10', 'Alerta', 3, 3),
(284.400, '2024-09-23 07:07:07', 'Normal', 4, 4),
(289.900, '2024-10-01 11:11:11', 'Critico', 5, 5),
(294.800, '2024-10-09 13:13:13', 'Normal', 6, 6),
(299.000, '2024-10-17 16:16:16', 'Normal', 7, 7),
(265.800, '2024-10-25 12:12:12', 'Normal', 8, 8),
(271.300, '2024-11-02 14:14:14', 'Normal', 9, 9),
(276.400, '2024-11-10 18:18:18', 'Alerta', 10, 10),
(270.900, '2024-11-18 08:30:30', 'Normal', 1, 1),
(275.600, '2024-11-26 09:40:40', 'Normal', 2, 2),
(280.200, '2024-12-04 10:50:50', 'Alerta', 3, 3),
(285.700, '2024-12-12 07:20:20', 'Normal', 4, 4),
(290.100, '2024-12-20 11:05:05', 'Critico', 5, 5),
(295.900, '2024-12-28 13:25:25', 'Normal', 6, 6),
(299.500, '2024-12-31 23:59:59', 'Normal', 7, 7),
(266.200, '2023-05-05 12:12:12', 'Normal', 8, 8),
(271.700, '2023-06-06 14:14:14', 'Normal', 9, 9),
(276.900, '2023-07-07 18:18:18', 'Alerta', 10, 10),
(267.300, '2025-01-02 08:08:08', 'Normal', 1, 1),
(272.100, '2025-01-10 09:09:09', 'Normal', 2, 2),
(277.600, '2025-01-18 10:10:10', 'Alerta', 3, 3),
(282.200, '2025-01-26 07:07:07', 'Normal', 4, 4),
(287.800, '2025-02-03 11:11:11', 'Critico', 5, 5),
(292.300, '2025-02-11 13:13:13', 'Normal', 6, 6),
(296.700, '2025-02-19 16:16:16', 'Normal', 7, 7),
(263.900, '2025-02-27 12:12:12', 'Normal', 8, 8),
(269.000, '2025-03-07 14:14:14', 'Normal', 9, 9),
(274.500, '2025-03-15 18:18:18', 'Alerta', 10, 10),
(268.200, '2025-03-23 08:30:30', 'Normal', 1, 1),
(273.400, '2025-03-31 09:40:40', 'Normal', 2, 2),
(278.900, '2025-04-08 10:50:50', 'Alerta', 3, 3),
(283.600, '2025-04-16 07:20:20', 'Normal', 4, 4),
(288.200, '2025-04-24 11:05:05', 'Critico', 5, 5),
(293.700, '2025-05-02 13:25:25', 'Normal', 6, 6),
(297.100, '2025-05-10 16:35:35', 'Normal', 7, 7),
(264.800, '2025-05-18 12:00:00', 'Normal', 8, 8),
(270.600, '2025-05-26 14:22:22', 'Normal', 9, 9),
(275.900, '2025-06-03 18:45:45', 'Alerta', 10, 10),
(269.700, '2025-06-11 08:08:08', 'Normal', 1, 1),
(274.200, '2025-06-19 09:09:09', 'Normal', 2, 2),
(279.100, '2025-06-27 10:10:10', 'Alerta', 3, 3),
(284.900, '2025-07-05 07:07:07', 'Normal', 4, 4),
(289.600, '2025-07-13 11:11:11', 'Critico', 5, 5),
(294.400, '2025-07-21 13:13:13', 'Normal', 6, 6),
(298.900, '2025-07-29 16:16:16', 'Normal', 7, 7),
(265.100, '2025-08-06 12:12:12', 'Normal', 8, 8),
(271.000, '2025-08-14 14:14:14', 'Normal', 9, 9),
(276.200, '2025-08-22 18:18:18', 'Alerta', 10, 10),
(270.300, '2025-08-30 08:30:30', 'Normal', 1, 1),
(275.800, '2025-09-07 09:40:40', 'Normal', 2, 2),
(280.400, '2025-09-15 10:50:50', 'Alerta', 3, 3),
(285.100, '2025-09-23 07:20:20', 'Normal', 4, 4),
(290.700, '2025-10-01 11:05:05', 'Critico', 5, 5),
(295.300, '2025-10-09 13:25:25', 'Normal', 6, 6),
(299.200, '2025-10-17 16:35:35', 'Normal', 7, 7),
(266.500, '2025-10-25 12:00:00', 'Normal', 8, 8),
(272.400, '2025-11-02 14:22:22', 'Normal', 9, 9),
(277.800, '2025-11-10 18:45:45', 'Alerta', 10, 10),
(271.000, '2025-11-18 08:08:08', 'Normal', 1, 1),
(276.200, '2025-11-26 09:09:09', 'Normal', 2, 2),
(281.500, '2025-12-04 10:10:10', 'Alerta', 3, 3),
(286.900, '2025-12-12 07:07:07', 'Normal', 4, 4),
(291.400, '2025-12-20 11:11:11', 'Critico', 5, 5),
(296.800, '2025-12-28 13:13:13', 'Normal', 6, 6),
(300.000, '2025-12-30 16:16:16', 'Normal', 7, 7),
(267.200, '2024-02-02 12:12:12', 'Normal', 8, 8),
(272.900, '2024-03-03 14:14:14', 'Normal', 9, 9),
(278.300, '2024-04-04 18:18:18', 'Alerta', 10, 10);

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

select * from pesagem;