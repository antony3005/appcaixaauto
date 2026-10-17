---
status: PARCIAL
ultima_revisao: 2026-09-14
---
# Produtos do Condomínio

Voltar para [[index-00-app-cliente]]. Relacionada a [[20-home]], [[22-produto-detalhe]], [[23-promocoes]] e [[24-busca-e-filtros]].

## Frontend preparado

- `ProductSummary`, `ProductCard`, `CatalogPage` e `ProductDetailPage`.
- Cards exibem foto/fallback, nome, categoria, unidade, preço e preço promocional recebido.
- Não existe comprar, adicionar, carrinho, checkout ou pagamento.
- Busca local só é habilitada quando `catalogSearchIsComplete=true` indica lista integral.

## Backend

`GET /terminais/{terminalId}/produtos-disponiveis` retorna o contrato técnico correto, porém o cliente não recebe Condomínio/Terminal de forma autorizada. Nenhum endpoint foi inventado ou chamado.
