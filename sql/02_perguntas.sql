
USE pncp_controladoria;

-- ===========================================================================
-- 1) ECONOMIA GLOBAL DO PODER PÚBLICO
-- Percentual e valor nominal economizado nos itens comparáveis
-- ===========================================================================

SELECT
    SUM(
        CASE WHEN comparavel = 1
             THEN valor_total_estimado ELSE 0
        END
    ) AS total_estimado_comparavel,

    SUM(
        CASE WHEN comparavel = 1
             THEN valor_total_homologado ELSE 0
        END
    ) AS total_homologado_comparavel,

    SUM(
        CASE WHEN comparavel = 1
             THEN economia_valor ELSE 0
        END
    ) AS economia_nominal,

    100.0 * SUM(
        CASE WHEN comparavel = 1
             THEN economia_valor ELSE 0
        END
    ) / NULLIF(
        SUM(
            CASE WHEN comparavel = 1
                 THEN valor_total_estimado ELSE 0
            END
        ), 0
    ) AS economia_percentual

FROM fato_item_contratado;


-- ===========================================================================
-- 2) CONCENTRAÇÃO E RISCO DE FORNECEDORES
-- Dez maiores fornecedores por volume homologado e participação no total
-- ===========================================================================

SELECT
    f.ni_fornecedor,
    f.nome_fornecedor,
    SUM(ft.valor_total_homologado) AS volume_homologado,

    100.0 * SUM(ft.valor_total_homologado) /
    NULLIF(
        (SELECT SUM(valor_total_homologado)
         FROM fato_item_contratado), 0
    ) AS percentual_total

FROM fato_item_contratado ft
INNER JOIN dim_fornecedor f
    ON ft.sk_fornecedor = f.sk_fornecedor

GROUP BY
    f.ni_fornecedor,
    f.nome_fornecedor

ORDER BY volume_homologado DESC
LIMIT 10;


-- ===========================================================================
-- 3) EFICÁCIA POR MODALIDADE
-- Economia percentual e volume de recursos por modalidade
-- ===========================================================================

SELECT
    m.modalidade_id,
    m.nome_modalidade,

    SUM(ft.valor_total_homologado) AS volume_homologado,

    SUM(
        CASE WHEN ft.comparavel = 1
             THEN ft.economia_valor ELSE 0
        END
    ) AS economia_nominal,

    100.0 * SUM(
        CASE WHEN ft.comparavel = 1
             THEN ft.economia_valor ELSE 0
        END
    ) / NULLIF(
        SUM(
            CASE WHEN ft.comparavel = 1
                 THEN ft.valor_total_estimado ELSE 0
            END
        ), 0
    ) AS economia_percentual

FROM fato_item_contratado ft
INNER JOIN dim_modalidade m
    ON ft.sk_modalidade = m.sk_modalidade

GROUP BY
    m.modalidade_id,
    m.nome_modalidade

ORDER BY volume_homologado DESC;


-- ===========================================================================
-- 4) TEMPO DO CICLO DE COMPRAS
-- Média de dias entre publicação e homologação por órgão
-- Considera órgãos com pelo menos 5 itens com ciclo válido
-- ===========================================================================

SELECT
    o.nome_orgao,
    COUNT(ft.dias_ciclo) AS itens_com_ciclo,
    AVG(ft.dias_ciclo) AS media_dias_ciclo,
    MAX(ft.dias_ciclo) AS maximo_dias_ciclo

FROM fato_item_contratado ft
INNER JOIN dim_orgao o
    ON ft.sk_orgao = o.sk_orgao

GROUP BY o.nome_orgao

HAVING COUNT(ft.dias_ciclo) >= 5

ORDER BY media_dias_ciclo DESC;


-- ===========================================================================
-- 5) DISTRIBUIÇÃO REGIONAL
-- Despesas e indicadores de desconto por estado e região
-- ===========================================================================

SELECT
    l.regiao,
    l.uf_sigla,
    l.uf_nome,

    SUM(ft.valor_total_homologado) AS volume_homologado,

    SUM(
        CASE WHEN ft.comparavel = 1
             THEN ft.economia_valor ELSE 0
        END
    ) AS economia_nominal,

    100.0 * SUM(
        CASE WHEN ft.comparavel = 1
             THEN ft.economia_valor ELSE 0
        END
    ) / NULLIF(
        SUM(
            CASE WHEN ft.comparavel = 1
                 THEN ft.valor_total_estimado ELSE 0
            END
        ), 0
    ) AS economia_percentual

FROM fato_item_contratado ft
INNER JOIN dim_localidade l
    ON ft.sk_localidade = l.sk_localidade

GROUP BY
    l.regiao,
    l.uf_sigla,
    l.uf_nome

ORDER BY volume_homologado DESC;


-- ===========================================================================
-- 6) PERFIL DOS GASTOS
-- Distribuição dos recursos entre bens, serviços e obras e engenharia
-- ===========================================================================

SELECT
    perfil_gasto,

    SUM(valor_total_homologado) AS volume_homologado,

    100.0 * SUM(valor_total_homologado) /
    NULLIF(
        (SELECT SUM(valor_total_homologado)
         FROM fato_item_contratado), 0
    ) AS percentual_volume,

    COUNT(*) AS quantidade_itens

FROM fato_item_contratado

GROUP BY perfil_gasto

ORDER BY volume_homologado DESC;
