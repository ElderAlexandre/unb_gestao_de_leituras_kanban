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
