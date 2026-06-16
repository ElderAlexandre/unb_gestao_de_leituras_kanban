-- ====================================================================
-- SISTEMA KANBAN DE LEITURAS UNB
-- ====================================================================

-- 1. CRIAÇÃO DAS TABELAS (DDL)
CREATE TABLE aluno (
    id_aluno SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    matricula VARCHAR(20) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    senha_hash VARCHAR(255) NOT NULL
);

CREATE TABLE professor (
    id_professor SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    departamento VARCHAR(50),
    email VARCHAR(100) UNIQUE
);

CREATE TABLE disciplina (
    id_disciplina SERIAL PRIMARY KEY,
    codigo_disciplina VARCHAR(20) UNIQUE NOT NULL,
    nome_disciplina VARCHAR(100) NOT NULL,
    id_professor INT REFERENCES professor(id_professor) ON DELETE SET NULL
);

CREATE TABLE categoria (
    id_categoria SERIAL PRIMARY KEY,
    nome_categoria VARCHAR(50) NOT NULL
);

CREATE TABLE livro (
    id_livro SERIAL PRIMARY KEY,
    titulo VARCHAR(150) NOT NULL,
    autor VARCHAR(100) NOT NULL,
    isbn VARCHAR(20) UNIQUE,
    num_paginas INT CHECK (num_paginas > 0),
    id_categoria INT REFERENCES categoria(id_categoria) ON DELETE RESTRICT
);

CREATE TABLE disciplina_livro (
    id_disciplina INT REFERENCES disciplina(id_disciplina) ON DELETE CASCADE,
    id_livro INT REFERENCES livro(id_livro) ON DELETE CASCADE,
    PRIMARY KEY (id_disciplina, id_livro)
);

CREATE TABLE quadro (
    id_quadro SERIAL PRIMARY KEY,
    nome_quadro VARCHAR(50) NOT NULL,
    data_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    id_aluno INT REFERENCES aluno(id_aluno) ON DELETE CASCADE
);

CREATE TABLE raia_swimlane (
    id_raia SERIAL PRIMARY KEY,
    nome_raia VARCHAR(50) NOT NULL,
    id_quadro INT REFERENCES quadro(id_quadro) ON DELETE CASCADE
);

CREATE TABLE cartao_kanban (
    id_cartao SERIAL PRIMARY KEY,
    coluna_status VARCHAR(20) NOT NULL CHECK (coluna_status IN ('A FAZER', 'FAZENDO', 'FEITO')),
    data_limite DATE,
    prioridade_cartao INT DEFAULT 1,
    id_quadro INT REFERENCES quadro(id_quadro) ON DELETE CASCADE,
    id_raia INT REFERENCES raia_swimlane(id_raia) ON DELETE SET NULL,
    id_livro INT REFERENCES livro(id_livro) ON DELETE CASCADE
);

CREATE TABLE fichamento (
    id_fichamento SERIAL PRIMARY KEY,
    notas_texto TEXT,
    arquivo_pdf_resumo BYTEA, 
    id_cartao INT REFERENCES cartao_kanban(id_cartao) ON DELETE CASCADE
);

CREATE TABLE historico_movimentacao (
    id_historico SERIAL PRIMARY KEY,
    coluna_origem VARCHAR(20),
    coluna_destino VARCHAR(20),
    data_hora_movimentacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    id_cartao INT REFERENCES cartao_kanban(id_cartao) ON DELETE CASCADE
);

-- ====================================================================
-- 2. REGRAS DE NEGÓCIO E AUTOMAÇÃO
-- ====================================================================

-- View de Leitura
CREATE OR REPLACE VIEW vw_resumo_kanban AS
SELECT 
    c.id_cartao,
    a.nome AS nome_aluno,
    q.nome_quadro AS quadro,
    l.titulo AS livro,
    c.coluna_status AS status_atual,
    c.data_limite
FROM 
    cartao_kanban c
JOIN quadro q ON c.id_quadro = q.id_quadro
JOIN aluno a ON q.id_aluno = a.id_aluno
JOIN livro l ON c.id_livro = l.id_livro;

-- Procedure de Atualização
CREATE OR REPLACE PROCEDURE sp_mover_cartao(
    p_id_cartao INT,
    p_novo_status VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_novo_status IN ('A FAZER', 'FAZENDO', 'FEITO') THEN
        UPDATE cartao_kanban
        SET coluna_status = p_novo_status
        WHERE id_cartao = p_id_cartao;
    ELSE
        RAISE EXCEPTION 'Status inválido. Use A FAZER, FAZENDO ou FEITO.';
    END IF;
END;
$$;

-- Trigger de Histórico (Gatilho)
CREATE OR REPLACE FUNCTION fn_registrar_historico()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.coluna_status IS DISTINCT FROM NEW.coluna_status THEN
        INSERT INTO historico_movimentacao (coluna_origem, coluna_destino, id_cartao)
        VALUES (OLD.coluna_status, NEW.coluna_status, NEW.id_cartao);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_historico_kanban
AFTER UPDATE ON cartao_kanban
FOR EACH ROW
EXECUTE FUNCTION fn_registrar_historico();

-- ====================================================================
-- 3. DADOS DE TESTE INICIAIS (DML)
-- ====================================================================

INSERT INTO aluno (nome, matricula, email, senha_hash) 
VALUES ('Elder Machado', '242012092', 'elder@aluno.unb.br', 'senha123');

INSERT INTO categoria (nome_categoria) VALUES ('Computação');

INSERT INTO livro (titulo, autor, isbn, num_paginas, id_categoria) 
VALUES ('Sistemas de Banco de Dados', 'Elmasri', '123456789', 700, 1);

INSERT INTO quadro (nome_quadro, id_aluno) VALUES ('Semestre 2026/1', 1);

INSERT INTO raia_swimlane (nome_raia, id_quadro) VALUES ('Prioridade Alta', 1);

INSERT INTO cartao_kanban (coluna_status, data_limite, id_quadro, id_raia, id_livro) 
VALUES ('A FAZER', '2026-07-01', 1, 1, 1);
