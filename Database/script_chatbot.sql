CREATE DATABASE chatbot;
USE chatbot;

CREATE TABLE cliente (
    id INTEGER PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(50)
);

CREATE TABLE chat (
    id INTEGER PRIMARY KEY AUTO_INCREMENT,
    passo_atual VARCHAR(50),
    dados_contexto JSON,
    data_atualizacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    cliente_id INTEGER UNIQUE,
    FOREIGN KEY(cliente_id) REFERENCES cliente(id)
);

SELECT
    chat.id AS chat_id,
    chat.passo_atual,
    chat.dados_contexto,
    chat.data_atualizacao,
    cliente.id AS cliente_id,
    cliente.nome AS cliente_nome
FROM chat
LEFT JOIN cliente ON chat.cliente_id = cliente.id;