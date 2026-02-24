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

-- 11. Ticket Médio por Tipo de Cliente:
-- Qual é o ticket médio (valor médio gasto por pedido/venda) separado por tipo de cliente (Cooperativa vs. Produtor Direto)?

select  c.nome_cliente,
round(sum(v.quantidade * p.preco_unitario) / count(v.id_venda), 2) as Ticket_Médio
from vendas v 
join clientes c on v.id_cliente = c.id_cliente
join produtos p on v.id_produto = p.id_produto
group by c.tipo;


-- 12. Clientes Inativos (Churn):
-- A diretoria quer saber quem comprou em 2023, mas não comprou nada em 2024. Liste o nome desses clientes.

with clientes2023 as (
    select c.id_cliente,c.nome_cliente, substr(v.data_venda, 1, 4)
    from vendas v 
    join clientes c on v.id_cliente = c.id_cliente
    where substr(v.data_venda, 1, 4) = '2023'
    group by c.nome_cliente, c.id_cliente
),
clientes2024 as (
    select c.id_cliente,c.nome_cliente, substr(v.data_venda, 1, 4)
    from vendas v 
    join clientes c on v.id_cliente = c.id_cliente
    where substr(v.data_venda, 1, 4) = '2024'
    group by c.nome_cliente, c.id_cliente
)
select c23.id_cliente, c23.nome_cliente
from clientes2023 c23
left join clientes2024 c24 on c23.id_cliente = c24.id_cliente
where c24.id_cliente is null;


-- 13. Recência de Compra (Dias desde a última compra):
-- Para cada cliente, mostre o Nome, a data da última compra que ele fez e quantos dias se passaram desde essa última compra até a 
-- data atual (ou até '2024-12-31' para simularmos o fim do ano).

with ultima_data_compra as (
    select c.id_cliente,
    c.nome_cliente, 
    max(v.data_venda) as ultimo_dia
    from vendas v 
    join clientes c on v.id_cliente = c.id_cliente
    group by c.nome_cliente, c.id_cliente
    order by max(v.data_venda) desc
)
select id_cliente,
nome_cliente,
julianday('2024-12-31') - julianday(ultimo_dia) as dias_desde_ultima_compra
from ultima_data_compra
order by dias_desde_ultima_compra desc;


-- 14. Os "Gigantes" (Acima da Média):
-- Quais clientes têm um faturamento total que é maior que o faturamento médio de todos os clientes da empresa?

with total_gasto_cliente as (
    select c.id_cliente, 
    c.nome_cliente,
    sum(v.quantidade * p.preco_unitario) as total_cliente from vendas v
    join clientes c on  v.id_cliente = c.id_cliente
    join produtos p on v.id_produto = p.id_produto
    group by c.id_cliente, c.nome_cliente
),
media_geral_gasto as (
    select 
    avg(total_cliente) as media_geral
    from total_gasto_cliente
)
select id_cliente, nome_cliente
from total_gasto_cliente
where total_cliente > (select media_geral from media_geral_gasto);


-- 15. Crescimento Ano a Ano (YoY - Year over Year):
-- Compare o faturamento total do ano de 2023 com o de 2024. Mostre em uma linha: Faturamento 2023, 
-- Faturamento 2024 e a variação percentual de crescimento.

with total_2023 as (
    select
    sum(v.quantidade * p.preco_unitario) as total_23 from vendas v
    join produtos p on v.id_produto = p.id_produto
    where v.data_venda >= '2023-01-01' and v.data_venda < '2024-01-01'
),
total_2024 as (
    select
    sum(v.quantidade * p.preco_unitario) as total_24 from vendas v
    join produtos p on v.id_produto = p.id_produto
    where v.data_venda >= '2024-01-01' and v.data_venda < '2025-01-01'
)
select total_23, total_24,
round(((total_24 - total_23) * 100.0) / total_23, 2) as variacao_percentual
from total_2023 t23
cross join total_2024;


-- 16. Média Móvel de 3 Meses:
-- Apresente o faturamento mês a mês de 2024 e, ao lado, a média móvel dos últimos 3 meses (o mês atual e os dois anteriores).
--  O Agro usa muito isso para suavizar as variações de safra.

with total2024 as (
    select substr(v.data_venda, 1, 7) as mes,
    sum(v.quantidade * p.preco_unitario) as total_2024 from vendas v
    join produtos p on v.id_produto = p.id_produto
    where v.data_venda >= '2024-01-01' and v.data_venda < '2025-01-01'
    group by substr(v.data_venda, 1, 7)
    order by substr(v.data_venda, 1, 7) asc
)
select mes,
total_2024,
round(avg(total_2024) over (ORDER BY mes ROWS BETWEEN 2 PRECEDING AND CURRENT ROW),2 ) as media_movel
from total2024;


-- 17. O Pior Mês de 2024:
-- Escreva uma query que retorne diretamente apenas uma linha: o mês de 2024 que teve o menor faturamento, junto com o valor faturado.

select substr(v.data_venda, 1, 7) as mes,
sum(v.quantidade * p.preco_unitario) as valor_faturado from vendas v
join produtos p on v.id_produto = p.id_produto
where v.data_venda >= '2024-01-01' and v.data_venda < '2025-01-01'
group by substr(v.data_venda, 1, 7)
order by valor_faturado asc
limit 1;


-- 18. Penetração de Tecnologia:
-- Quais Regiões (nome_regiao) já realizaram compras de produtos da categoria 'Tecnologia'? Mostre a região e o total faturado apenas nessa categoria.

select r.nome_regiao,
sum(v.quantidade * p.preco_unitario) as total_faturado
from regioes r
join clientes c on r.id_regiao = c.id_regiao
join vendas v on c.id_cliente = v.id_cliente
join produtos p on v.id_produto = p.id_produto
where p.categoria = 'Tecnologia'
group by r.id_regiao, r.nome_regiao;


-- 19. Vendas Cruzadas (Cross-Sell de Sementes e Químicos):
-- Identifique os clientes que já compraram ambas as categorias: 'Sementes' E 'Químicos'. Retorne apenas o nome do cliente.

select c.nome_cliente from clientes c
join vendas v on c.id_cliente = v.id_cliente
join produtos p on v.id_produto = p.id_produto
where p.categoria in ('Sementes','Químicos')
group by c.nome_cliente
having count(distinct p.categoria) = 2;


-- 20. Percentual de Representatividade Interna da Região:
-- Para cada produto vendido dentro da região "Sul", qual foi o seu faturamento e quantos % esse produto representa 
-- no faturamento TOTAL apenas da região Sul?

with total_por_produto as (
    select p.nome_produto,r.nome_regiao,
    sum(v.quantidade * p.preco_unitario) as total_faturado_produto
    from regioes r
    join clientes c on r.id_regiao = c.id_regiao
    join vendas v on c.id_cliente = v.id_cliente
    join produtos p on v.id_produto = p.id_produto
    where r.nome_regiao = 'Sul'
    group by p.nome_produto, r.nome_regiao
)
select *,
round((total_faturado_produto * 100.00) / sum(total_faturado_produto) over (), 2) as porcentagem_no_total
from total_por_produto;


-- 21. Clientes em Risco (Churn):
-- Identifique clientes que fizeram compras em 2023, mas não realizaram nenhuma compra em 2024.

with clientes2023 as (
    select c.id_cliente, c.nome_cliente from vendas v
    join clientes c on v.id_cliente = c.id_cliente
    where v.data_venda >= '2023-01-01' and v.data_venda <'2024-01-01'
    group by c.id_cliente,c.nome_cliente
),
clientes2024 as (
    select distinct id_cliente
    from vendas
    where data_venda >= '2024-01-01'
)
select c23.* from clientes2023 c23
left join clientes2024 c24 on c23.id_cliente = c24.id_cliente
where c24.id_cliente is null;


-- 22. O "Embaixador" da Marca:
-- Qual cliente comprou a maior variedade de produtos diferentes (contagem de id_produto distintos) em toda a história?

select 
c.nome_cliente,
count(distinct p.id_produto) as conta_de_produtos
from clientes c
join vendas v on c.id_cliente = v.id_cliente
join produtos p on v.id_produto = p.id_produto
group by c.id_cliente, c.nome_cliente
order by conta_de_produtos desc
limit 1;


-- 23. Intervalo Médio de Compras (Cycle Time):
-- Para o cliente que mais compra, qual a média de dias entre um pedido e outro?

with campeao as (
    select c.id_cliente,
    count(v.id_venda) as qtde_compras
    from vendas v
    join clientes c on v.id_cliente = c.id_cliente
    group by c.id_cliente
    order by qtde_compras desc
    limit 1
),
historico_compras as (
    select v.data_venda 
    from vendas v
    where v.id_cliente = (select id_cliente from campeao)
),
dias_entre_compras as (
    select data_venda,
    lag(data_venda) over (order by data_venda) as data_compra_anterior
    from historico_compras
)
select avg(julianday(data_venda) - julianday(data_compra_anterior)) as media_dias_entre_compras
from dias_entre_compras
WHERE data_compra_anterior IS NOT NULL;


-- 24. Produtos de "Cauda Longa":
-- Liste os produtos que representam os últimos 5% do faturamento total. (Aqueles que vendem muito pouco e talvez não valha a pena ter no estoque).

with total_produtos as (
    select 
    p.nome_produto,
    sum(p.preco_unitario * v.quantidade) as faturamento_item
    from vendas v
    join produtos p on v.id_produto = p.id_produto
    GROUP BY p.nome_produto
),
calculo_acumulado as (
    select nome_produto,
    faturamento_item,
    sum(faturamento_item) over (order by faturamento_item asc) as faturamento_acumulado,
    sum(faturamento_item) over() as faturamento_total
    from total_produtos
),
percentual as (
    select 
        nome_produto,
        round((faturamento_acumulado * 100.0) / faturamento_total, 2) as quanto_representa
    from calculo_acumulado
)
select *
from percentual
where quanto_representa <= 5.00;


-- 25. Ranking de Vendas por Região (Top 3):
-- Para cada região, liste os 3 produtos mais vendidos (em valor).

with total_por_regiao as (
    select 
    r.id_regiao,
    r.nome_regiao,
    p.nome_produto,
    sum(p.preco_unitario * v.quantidade) as total from 
    regioes r
    join clientes c on r.id_regiao = c.id_regiao
    join vendas v on c.id_cliente = v.id_cliente
    join produtos p on v.id_produto = p.id_produto
    group by r.id_regiao, r.nome_regiao, p.nome_produto
),
ranque_por_regiao as (
    select *,
    dense_rank() over (PARTITION BY nome_regiao order by total desc) as ranque
    from total_por_regiao
)
select * from ranque_por_regiao
where ranque <= 3;


-- 26. Sazonalidade de Categoria:
-- Em qual mês do ano a categoria 'Sementes' atinge seu pico de faturamento?

select 
p.categoria,
substr(v.data_venda, 1, 7) as mes,
sum(p.preco_unitario * v.quantidade) as total from 
vendas v 
join produtos p on v.id_produto = p.id_produto
where p.categoria = 'Sementes'
group by p.categoria, substr(v.data_venda, 1, 7)
order by total desc
limit 1;

-- 27. Ticket Médio por Tipo de Cliente:
-- Compare o ticket médio (Faturamento Total / Total de Pedidos) entre 'Produtor Direto' e 'Cooperativa'.

select 
c.tipo,
sum(v.quantidade * p.preco_unitario) as faturamento_total,
count(v.id_venda) as total_pedidos,
sum(v.quantidade * p.preco_unitario) / count(v.id_venda) as ticket_médio
 from clientes c

join vendas v on c.id_cliente = v.id_cliente

join produtos p on v.id_produto = p.id_produto

where c.tipo in ('Produtor Direto', 'Cooperativa')

group by c.tipo


-- 28. Impacto de Devolução (Simulação):
-- Se todos os pedidos com menos de 10 itens fossem cancelados, quanto o faturamento total de 2024 seria reduzido (em %)

with total_2024 as (
select sum(v.quantidade * p.preco_unitario) as total2024
from vendas v 

join produtos p on v.id_produto = p.id_produto

where v.data_venda >= '2024-01-01'
and v.data_venda < '2025-01-01'
),

menos_de_10_produtos as (
select 
sum(v.quantidade * p.preco_unitario) as total_com_10_produtos

from vendas v 

join produtos p on v.id_produto = p.id_produto

where v.quantidade < 10 and 
substr(v.data_venda, 1, 4) = '2024'
)

select 
round((total_com_10_produtos * 100.00) / total2024, 2) as faturamento_reduzido
from menos_de_10_produtos, total_2024



-- 29. Clientes de "Compra Única":
-- Qual a porcentagem de clientes que compraram duas vezes ou menos e nunca mais voltaram?

with duas_vezes as (
select count(*) as total_clientes_2
from (
    select id_cliente
    from vendas
    group by id_cliente
    having count(*) <= 2
) as clientes_com_2_vendas
),

total as (
select 
     count(distinct id_cliente) as total_clientes
from vendas
)

select 
round((total_clientes_2 * 100.0) / total_clientes, 2) as porcentagem
from duas_vezes, total


-- 30. Relatório Executivo Acumulado (Running Total):
-- Crie uma query que mostre o faturamento mês a mês de 2024, mas com uma coluna extra de Faturamento Acumulado.

with totais as (
    select 
        substr(v.data_venda, 1, 7) as mes,
        sum(v.quantidade * p.preco_unitario) as total
    from vendas v
    join produtos p on v.id_produto = p.id_produto
    where v.data_venda >= '2024-01-01'
      and v.data_venda < '2025-01-01'
    group by substr(v.data_venda, 1, 7)
)

select *,
    sum(total) over (order by mes) as faturamento_acumulado
from totais
order by mes
