-- Projeto Final - Módulo 2
-- COMO USAR (passo a passo):
--   1) Abra o MySQL Workbench e conecte no seu servidor (Local instance).
--   2) Abra uma aba de query (SQL) em branco.
--   3) Copie TODO o conteudo deste arquivo (Ctrl+A, Ctrl+C aqui no .txt).
--   4) Cole na aba de query do Workbench (Ctrl+V).
--   5) Clique no raio (ou aperte Ctrl+Shift+Enter) para EXECUTAR tudo.
--   6) Pronto! O banco 'transparencia' e as tabelas estarao criados.
--      Agora siga para a Fase 1 (python 1_extrair.py).
--
-- IMPORTANTE: rode este script UMA vez, ANTES dos scripts Python. Os scripts
-- Python NAO criam tabelas: eles apenas inserem/transformam os dados.
-- O nome do banco (transparencia) deve ser o MESMO do .env (variavel MYSQL_DATABASE).

CREATE DATABASE IF NOT EXISTS pncp_controladoria;
USE pncp_controladoria;

-- =========================================================
-- DIMENSÃO: ÓRGÃO
-- =========================================================
CREATE TABLE IF NOT EXISTS dim_orgao (
    sk_orgao INT NOT NULL,
    cnpj_orgao VARCHAR(20) NOT NULL,
    nome_orgao VARCHAR(255),
    poder VARCHAR(30),

    PRIMARY KEY (sk_orgao),
    UNIQUE KEY uq_dim_orgao_cnpj (cnpj_orgao)
);

-- =========================================================
-- DIMENSÃO: FORNECEDOR
-- =========================================================
CREATE TABLE IF NOT EXISTS dim_fornecedor (
    sk_fornecedor INT NOT NULL,
    ni_fornecedor VARCHAR(20) NOT NULL,
    nome_fornecedor VARCHAR(255),
    tipo_pessoa VARCHAR(30),
    porte VARCHAR(50),

    PRIMARY KEY (sk_fornecedor),
    UNIQUE KEY uq_dim_fornecedor_ni (ni_fornecedor)
);

-- =========================================================
-- DIMENSÃO: MODALIDADE
-- =========================================================
CREATE TABLE IF NOT EXISTS dim_modalidade (
    sk_modalidade INT NOT NULL,
    modalidade_id INT NOT NULL,
    nome_modalidade VARCHAR(150),

    PRIMARY KEY (sk_modalidade),
    UNIQUE KEY uq_dim_modalidade_id (modalidade_id)
);

-- =========================================================
-- DIMENSÃO: LOCALIDADE
-- =========================================================
CREATE TABLE IF NOT EXISTS dim_localidade (
    sk_localidade INT NOT NULL,
    uf_sigla VARCHAR(2) NOT NULL,
    uf_nome VARCHAR(50),
    regiao VARCHAR(30),

    PRIMARY KEY (sk_localidade),
    UNIQUE KEY uq_dim_localidade_uf (uf_sigla)
);

-- =========================================================
-- FATO: ITEM CONTRATADO
-- =========================================================
CREATE TABLE IF NOT EXISTS fato_item_contratado (
    sk_fato INT NOT NULL AUTO_INCREMENT,
    numero_controle_pncp VARCHAR(100) NOT NULL,
    numero_item INT NOT NULL,

    sk_orgao INT NOT NULL,
    sk_fornecedor INT NOT NULL,
    sk_modalidade INT NOT NULL,
    sk_localidade INT NOT NULL,

    data_publicacao DATE,
    data_homologacao DATE,

    descricao_item TEXT,
    perfil_gasto VARCHAR(50),

    quantidade DECIMAL(18,4) NOT NULL,
    valor_unitario_estimado DECIMAL(18,4) NOT NULL,
    valor_total_estimado DECIMAL(18,2) NOT NULL,
    valor_unitario_homologado DECIMAL(18,4) NOT NULL,
    valor_total_homologado DECIMAL(18,2) NOT NULL,

    comparavel TINYINT NOT NULL,
    economia_valor DECIMAL(18,2) NULL,
    dias_ciclo INT NULL,

    PRIMARY KEY (sk_fato),

    UNIQUE KEY uq_fato_item (
        numero_controle_pncp,
        numero_item
    ),

    CONSTRAINT fk_fato_orgao
        FOREIGN KEY (sk_orgao)
        REFERENCES dim_orgao (sk_orgao),

    CONSTRAINT fk_fato_fornecedor
        FOREIGN KEY (sk_fornecedor)
        REFERENCES dim_fornecedor (sk_fornecedor),

    CONSTRAINT fk_fato_modalidade
        FOREIGN KEY (sk_modalidade)
        REFERENCES dim_modalidade (sk_modalidade),

    CONSTRAINT fk_fato_localidade
        FOREIGN KEY (sk_localidade)
        REFERENCES dim_localidade (sk_localidade),

    CONSTRAINT chk_fato_quantidade
        CHECK (quantidade > 0),

    CONSTRAINT chk_fato_valores
        CHECK (
            valor_unitario_estimado >= 0
            AND valor_total_estimado >= 0
            AND valor_unitario_homologado >= 0
            AND valor_total_homologado >= 0
        ),

    CONSTRAINT chk_fato_comparavel
        CHECK (comparavel IN (0, 1))
);


-- ===========================================================================
-- RESUMO DAS CONSTRAINTS EXTRAS (Além das PK + FK)
-- ---------------------------------------------------------------------------
--                      CONSTRAINT 1                         CONSTRAINT 2
-- dim_orgao             UNIQUE em cnpj_orgao;                NOT NULL em cnpj_orgao
-- dim_fornecedor        UNIQUE em ni_fornecedor;             NOT NULL em ni_fornecedor
-- dim_modalidade        UNIQUE em modalidade_id;             NOT NULL em modalidade_id
-- dim_localidade        UNIQUE em uf_sigla;                  NOT NULL em uf_sigla
-- fato_item_contratado  UNIQUE em (numero_controle_pncp,     CHECK em quantidade > 0
--                       numero_item)
-- fato_item_contratado  CHECK em valores >= 0;               CHECK em comparavel IN (0, 1)
--
-- ===========================================================================