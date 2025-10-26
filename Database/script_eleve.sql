CREATE DATABASE eleve;
USE eleve;

CREATE TABLE usuario (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(256) NOT NULL UNIQUE,
    senha VARCHAR(100) NOT NULL
);

CREATE TABLE cliente (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(100) NOT NULL,
    telefone CHAR(11) NOT NULL,
    cep CHAR(8) NOT NULL,
    rua VARCHAR(100),
    num_endereco VARCHAR(10),
    bairro VARCHAR(50),
    cidade VARCHAR(50),
    complemento VARCHAR(100)
);

CREATE TABLE pacote (
    id INT PRIMARY KEY AUTO_INCREMENT,
    tipo VARCHAR(9) NOT NULL
);

CREATE TABLE cliente_pacote (
    id INT PRIMARY KEY AUTO_INCREMENT,
    cliente_id INT NOT NULL,
    pacote_id INT NOT NULL,
    data_inicio DATE,
    data_expiracao DATE,
    FOREIGN KEY (cliente_id) REFERENCES cliente(id),
    FOREIGN KEY (pacote_id) REFERENCES pacote(id)
);

CREATE TABLE porte (
	id INT PRIMARY KEY AUTO_INCREMENT,
    nome CHAR(7) NOT NULL
);

CREATE TABLE raca (
    id INT PRIMARY KEY AUTO_INCREMENT,
    porte_id INT NOT NULL,
    nome VARCHAR(100) NOT NULL,
    FOREIGN KEY (porte_id) REFERENCES porte(id)
);

CREATE TABLE pet (
    id INT PRIMARY KEY AUTO_INCREMENT,
    cliente_id INT NOT NULL,
    raca_id INT NOT NULL,
    nome VARCHAR(100) NOT NULL,
    FOREIGN KEY (cliente_id) REFERENCES cliente(id),
    FOREIGN KEY (raca_id) REFERENCES raca(id)
);

CREATE TABLE servico (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(100) NOT NULL,
    valor_base FLOAT NOT NULL
);

CREATE TABLE agenda (
    id INT PRIMARY KEY AUTO_INCREMENT,
    pet_id INT NOT NULL,
    valor_deslocamento FLOAT NOT NULL,
    data_hora_inicio DATETIME NOT NULL,
    data_hora_fim DATETIME NOT NULL,
    FOREIGN KEY (pet_id) REFERENCES pet(id)
);

CREATE TABLE agenda_servico (
    id INT PRIMARY KEY AUTO_INCREMENT,
    agenda_id INT NOT NULL,
    servico_id INT NOT NULL,
    valor FLOAT NOT NULL,
    FOREIGN KEY (agenda_id) REFERENCES agenda(id),
    FOREIGN KEY (servico_id) REFERENCES servico(id)
);

CREATE TABLE solicitacao_agenda (
    id INT PRIMARY KEY AUTO_INCREMENT,
    chat_id INT NOT NULL,
    pet_id INT NOT NULL,
    valor_deslocamento FLOAT,
    data_hora_inicio DATETIME NOT NULL,
    data_hora_fim DATETIME,
    status VARCHAR(27) NOT NULL,
    data_hora_solicitacao DATETIME NOT NULL,
    FOREIGN KEY (pet_id) REFERENCES pet(id)
);

CREATE TABLE solicitacao_agenda_servico (
    id INT PRIMARY KEY AUTO_INCREMENT,
    solicitacao_agenda_id INT NOT NULL,
    servico_id INT NOT NULL,
    valor FLOAT,
    FOREIGN KEY (solicitacao_agenda_id) REFERENCES solicitacao_agenda(id),
    FOREIGN KEY (servico_id) REFERENCES servico(id)
);

CREATE TABLE categoria_produto (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(100) NOT NULL
);

CREATE TABLE produto (
    id INT PRIMARY KEY AUTO_INCREMENT,
    categoria_produto_id INT NOT NULL,
    nome VARCHAR(100) NOT NULL,
    FOREIGN KEY (categoria_produto_id) REFERENCES categoria_produto(id)
);

CREATE TABLE despesa (
    id INT PRIMARY KEY AUTO_INCREMENT,
    produto_id INT NOT NULL,
    valor FLOAT NOT NULL,
    data DATETIME NOT NULL,
    FOREIGN KEY (produto_id) REFERENCES produto(id)
);

-- Usuário admin
INSERT INTO usuario (nome, email, senha)
VALUES ('Admin', 'admin@email.com', '$2a$10$8Kyvnk7du1AY6Yk1FrZILOsWtWcp4Hr79qNTux2xGRi6ODgxura0C');

-- Pacotes
INSERT INTO pacote (tipo)
VALUES ('Quinzenal'), ('Mensal');

-- Porte
INSERT INTO porte (nome)
VALUES ('Pequeno'), ('Médio'), ('Grande');  

-- Raças
INSERT INTO raca (nome, porte_id)
VALUES 
  -- Pequeno
  ('Boston Terrier', 1),
  ('Bulldog Francês', 1),
  ('Bulldog Inglês', 1),
  ('Bulldog', 1),
  ('Chihuahua', 1),
  ('Salsicha', 1),
  ('Spitz Alemão', 1),
  ('Maltês', 1),
  ('Pequinês', 1),
  ('Pinscher', 1),
  ('Poodle', 1),
  ('Shih Tzu', 1),
  ('Yorkshire', 1),
  ('Pug' , 1),
  
  -- Médio
  ('Caramelo', 2),
  ('Beagle', 2),
  ('Cocker Spaniel', 2),
  ('Fox Terrier', 2),
  ('Schnauzer', 2),
  ('Shar Pei', 2),
  ('Bull Terrier', 2),
  ('Whippet', 2),
  ('Jack russell', 2),
  ('Pit Bull', 2),
  ('American Bully', 2),

  -- Grande
  ('Bernese', 3),
  ('Boxer', 3),
  ('Doberman', 3),
  ('Dogue Alemão', 3),
  ('Golden', 3),
  ('Labrador', 3),
  ('Pastor Alemão', 3),
  ('Pastor Belga', 3),
  ('Pastor Suíço', 3),
  ('Rottweiler', 3),
  ('São Bernardo', 3),
  ('Husky Siberiano', 3),
  ('Weimaraner', 3);

-- Categorias de despesas
INSERT INTO categoria_produto (nome)
VALUES ('Gasto fixo'), ('Manutenção'), ('Insumo');

-- Produtos
INSERT INTO produto (nome, categoria_produto_id)
VALUES 
  -- Gasto fixo
  ('Aluguel', 1),
  ('Conta de Luz', 1),
  ('Conta de Água', 1),
  ('Internet', 1),

  -- Manutenção
  ('Máquina de Tosa', 2),
  ('Secador', 2),
  ('Tesoura', 2),
  ('Escova', 2),

  -- Insumo
  ('Algodão', 3),
  ('Toalha', 3),
  ('Papel Higiênico', 3),
  ('Sacos de Lixo', 3),
  ('Desinfetante', 3),
  ('Shampoo', 3),
  ('Condicionador', 3),
  ('Sabonete', 3),
  ('Perfume', 3);

-- Serviços
INSERT INTO servico (nome, valor_base)
VALUES 
    ('Banho', 35.00),
    ('Tosa', 50.00),
    ('Hidratação', 15.00);

-- Seleciona todos os pets com seus respectivos donos e raças
SELECT 
    pet.nome AS nome_pet,
    cliente.nome AS nome_cliente,
    raca.nome AS raca
FROM pet
JOIN cliente ON pet.cliente_id = cliente.id
JOIN raca ON pet.raca_id = raca.id;

-- Mostra todas Agendas com Cliente, Pet, Serviços e valor total
SELECT
    agenda.id AS id_agenda,
    cliente.nome AS cliente,
    pet.nome AS pet,
    GROUP_CONCAT(servico.nome SEPARATOR ', ') AS servicos,
    (SUM(agenda_servico.valor) + agenda.valor_deslocamento) AS valor_total,
    agenda.data_hora_inicio,
    agenda.data_hora_fim
FROM agenda
JOIN agenda_servico ON agenda.id = agenda_servico.agenda_id
JOIN servico ON agenda_servico.servico_id = servico.id
JOIN pet ON agenda.pet_id = pet.id
JOIN cliente ON pet.cliente_id = cliente.id
GROUP BY agenda.id;

-- Exibe todos solicitações de agendamentos com Cliente, Pet, Serviços, valor total, data/hora da solicitação e status
SELECT
    solicitacao_agenda.id AS id_agenda,
    status,
    cliente.nome AS cliente,
    pet.nome AS pet,
    GROUP_CONCAT(servico.nome SEPARATOR ', ') AS servicos,
    SUM(solicitacao_agenda_servico.valor) AS valor_servicos,
    solicitacao_agenda.valor_deslocamento,
    solicitacao_agenda.data_hora_inicio,
    solicitacao_agenda.data_hora_fim,
    solicitacao_agenda.data_hora_solicitacao
FROM solicitacao_agenda
JOIN solicitacao_agenda_servico ON solicitacao_agenda.id = solicitacao_agenda_servico.solicitacao_agenda_id
JOIN servico ON solicitacao_agenda_servico.servico_id = servico.id
JOIN pet ON solicitacao_agenda.pet_id = pet.id
JOIN cliente ON pet.cliente_id = cliente.id
GROUP BY solicitacao_agenda.id;

-- Lista todas as despesas, produtos relacionados e categorias
SELECT 
    despesa.id AS id_despesa,
    produto.nome AS produto,
    categoria_produto.nome AS categoria,
    despesa.valor,
    despesa.data
FROM despesa
JOIN produto ON despesa.produto_id = produto.id
JOIN categoria_produto ON produto.categoria_produto_id = categoria_produto.id;

-- Mostra quais clientes têm pacotes e quando eles expiram
SELECT 
    cliente.nome AS cliente,
    pacote.tipo AS tipo_pacote,
    cliente_pacote.data_expiracao
FROM cliente_pacote
JOIN cliente ON cliente_pacote.cliente_id = cliente.id
JOIN pacote ON cliente_pacote.pacote_id = pacote.id;

-- Lista todos os produtos e suas categorias
SELECT 
    produto.nome AS produto,
    categoria_produto.nome AS categoria
FROM produto
JOIN categoria_produto ON produto.categoria_produto_id = categoria_produto.id;

SELECT * FROM usuario;

SELECT * FROM raca;

SELECT * FROM produto;

SELECT * FROM categoria_produto;

SELECT * FROM cliente;

SELECT * FROM pet;