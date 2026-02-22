-- 1- Visão Geral: Qual é o faturamento total da empresa? (Dica: você precisará multiplicar a quantidade vendida pelo preço unitário).
select round(sum(p.preco_unitario * v.quantidade), 2) as faturamento_total
from produtos p 
join vendas v on p.id_produto = v.id_produto;

-- 2- Performance de Produto: Qual é o faturamento total e a quantidade total vendida por categoria de produto?
select p.categoria,
SUM(v.quantidade) AS qtd_total,
round(sum(preco_unitario * quantidade), 2) as total_por_categoria
from produtos p 
join vendas v on p.id_produto = v.id_produto
group by p.categoria;

-- 3- Análise de Clientes (Top Tier): Quais são os 3 clientes que mais geraram receita para a empresa? Retorne o nome do cliente e o valor total.
select c.nome_cliente,
round(sum(p.preco_unitario * v.quantidade), 2) as total_gasto
from clientes c 
join vendas v on c.id_cliente = v.id_cliente
join produtos p on v.id_produto = p.id_produto
where p.preco_unitario > 0 and v.quantidade > 0 
group by c.id_cliente, c.nome_cliente
order by total_gasto desc
limit 3;

-- 4 Análise Geográfica: Qual estado (estado) trouxe o maior volume financeiro em vendas? (Dica: exigirá múltiplos JOINs).
select r.estado,
round(sum(p.preco_unitario * v.quantidade), 2) as total_por_estado
from regioes r 
join clientes c on r.id_regiao = c.id_regiao
join vendas v on c.id_cliente = v.id_cliente
join produtos p on v.id_produto = p.id_produto
group by r.id_regiao, r.estado
order by total_por_estado desc
limit 1;

-- 5 Tendência Temporal (Avançado): Qual foi o faturamento total mês a mês? (Dica: extraia o mês/ano da data_venda e agrupe).
select 
substr(v.data_venda, 1, 7) as mes,
round(sum(p.preco_unitario * v.quantidade), 2) as total_por_mes
from produtos p 
join vendas v on p.id_produto = v.id_produto
group by substr(v.data_venda, 1, 7)
order by mes asc;

-- 6. Participação de Mercado (Market Share):
-- Apresente uma tabela com: Nome do Cliente, Faturamento total desse cliente e, em uma terceira coluna, 
-- o quanto esse cliente representa (em %) em relação ao faturamento total da empresa.
with total_cliente as (
select c.nome_cliente,
sum(p.preco_unitario * v.quantidade) as total_gasto
from clientes c
join vendas v on c.id_cliente = v.id_cliente
join produtos p on v.id_produto = p.id_produto
group by c.id_cliente, c.nome_cliente
order by total_gasto desc
),
total_das_empresas as (
select sum(preco_unitario * quantidade) as total
from vendas v
join produtos p on v.id_produto = p.id_produto
)
select *,
round((total_gasto * 100.0 / (select total from total_das_empresas)), 2) as representacao_clientes_porcentagem
from total_cliente
order by representacao_clientes_porcentagem desc;

-- 7. Ranking Regional por Categoria:
-- O gestor quer saber qual é o produto mais vendido (em faturamento)
-- dentro de cada Região. A tabela deve mostrar: Nome da Região, Nome do Produto, 
-- Faturamento e a posição dele no ranking (1º, 2º...) dentro daquela região específica.
with totalporregiao as (
select r.id_regiao, r.nome_regiao,
p.nome_produto,
sum(p.preco_unitario * v.quantidade) as faturamento
from regioes r 
join clientes c on r.id_regiao = c.id_regiao
join vendas v on c.id_cliente = v.id_cliente
join produtos p on v.id_produto = p.id_produto
group by r.id_regiao, r.nome_regiao, p.nome_produto
)
select nome_regiao,
nome_produto,
faturamento,
dense_rank() over (PARTITION BY nome_regiao order by faturamento desc) as ranking
from totalporregiao
order by nome_regiao;

-- 8. Análise de Crescimento (MoM - Month over Month):
-- Compare o faturamento de cada mês com o faturamento do mês anterior.
-- O resultado deve ter: Mês Atual, Faturamento Atual, Faturamento do Mês Anterior e a Diferença Percentual entre eles.
with atual as (
select
substr(v.data_venda,1,7) as mes_atual,
round(sum(v.quantidade * p.preco_unitario), 2) as faturamento_atual from vendas v
join produtos p on v.id_produto = p.id_produto
group by substr(v.data_venda,1,7)
)
select *,
lag(faturamento_atual) over (order by mes_atual) as mes_anterior,
round((faturamento_atual - LAG(faturamento_atual) OVER (ORDER BY mes_atual)) * 100.0 / NULLIF(LAG(faturamento_atual) OVER (ORDER BY mes_atual), 0)) AS diferenca_percentual
from atual
ORDER BY mes_atual;

-- 9. Comportamento de Compra (Fidelidade):
-- Identifique os clientes que compraram mais de uma categoria de produto diferente. 
-- Retorne o nome do cliente e a quantidade de categorias distintas que ele já adquiriu. Ordene pelos mais "diversificados".
select c.nome_cliente,
count(distinct p.categoria) as qtde_categorias_distintas
from clientes c
join vendas v on c.id_cliente = v.id_cliente
join produtos p on v.id_produto = p.id_produto
group by c.id_cliente, c.nome_cliente
having count(distinct p.categoria) > 1
order by qtde_categorias_distintas desc;

-- 10. Curva ABC de Produtos:
-- Classifique os produtos com base no faturamento acumulado. Você deve retornar: Nome do Produto,
-- Faturamento Individual e o Faturamento Acumulado Progressivo (a soma do faturamento dele com todos os anteriores no ranking).
with Faturamento_Individual_Produtos as (
select 
p.nome_produto,
round(sum(v.quantidade * p.preco_unitario), 2) as Faturamento_Individual
from vendas v 
join produtos p on p.id_produto = v.id_produto
group by p.id_produto, p.nome_produto
)
select *, 
sum(Faturamento_Individual) over (order by Faturamento_Individual desc) as FaturamentoAcumuladoProgressivo
from Faturamento_Individual_Produtos
order by Faturamento_Individual desc;