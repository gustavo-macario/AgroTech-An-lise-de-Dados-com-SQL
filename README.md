🌾 AgroTech | Análise de Dados com SQL
Projeto de estudo desenvolvido com foco em análise de dados utilizando SQL, simulando o cenário de uma empresa do setor agrícola chamada AgroTech.

# O objetivo foi aplicar conceitos de:
JOINs
GROUP BY
CTEs
Window Functions
Funções Analíticas
Ranking
Análise temporal
Cálculo de métricas de negócio


# Sobre o Projeto
A AgroTech é uma empresa fictícia do setor agropecuário que comercializa produtos como sementes, fertilizantes e defensivos agrícolas.
Este projeto responde a perguntas estratégicas de negócio a partir de consultas SQL estruturadas, simulando demandas reais de gestores.


# Tecnologias Utilizadas
SQL
Banco de dados relacional
CTEs
Window Functions
Funções analíticas


# Objetivo do Projeto
Este projeto foi desenvolvido como prática para:
Consolidar fundamentos de SQL
Simular problemas reais de negócio
Trabalhar com métricas financeiras
Desenvolver raciocínio analítico


# Tabelas do banco de dados utilizadas para as análises:

 1. Tabela de Regiões (Dimensão)
CREATE TABLE regioes (
    id_regiao INTEGER PRIMARY KEY,
    nome_regiao TEXT NOT NULL
);

 2. Tabela de Produtos (Dimensão)
CREATE TABLE produtos (
    id_produto INTEGER PRIMARY KEY,
    nome_produto TEXT NOT NULL,
    categoria TEXT NOT NULL, -- Ex: Sementes, Químicos, Tecnologia
    preco_unitario REAL NOT NULL
);

 3. Tabela de Clientes (Dimensão)
CREATE TABLE clientes (
    id_cliente INTEGER PRIMARY KEY,
    nome_cliente TEXT NOT NULL,
    tipo TEXT NOT NULL, -- Ex: Produtor Direto, Cooperativa
    id_regiao INTEGER,
    FOREIGN KEY (id_regiao) REFERENCES regioes(id_regiao)
);

 4. Tabela de Vendas (Fato)
CREATE TABLE vendas (
    id_venda INTEGER PRIMARY KEY,
    id_cliente INTEGER,
    id_produto INTEGER,
    quantidade INTEGER NOT NULL,
    data_venda DATE NOT NULL,
    FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente),
    FOREIGN KEY (id_produto) REFERENCES produtos(id_produto)
);
