---
status: PARCIAL
ultima_revisao: 2026-09-14
---
# Histórico de compras

Voltar para [[index-00-app-cliente]]. Relacionada a [[31-detalhe-compra]], [[32-comprovantes]] e [[14-cpf-e-historico-anterior]].

## Contrato consumido

`GET /user/{userId}/orders?page=&size=&sort=` entrega `orderId`, status, subtotal, desconto, total e data. `ClientApiRepository` converte apenas esses campos e não recalcula valores.

## UI

- `PurchasesPage` com refresh, vazio, erro preservando conteúdo e lista.
- `PurchaseCard` mostra data/hora, valor e `StatusChip` textual + ícone.
- Status reais mapeados: pending, created, at_terminal, processed, canceled, expired, failed, refunded e action_required.

## Limitação

O contrato não entrega Condomínio, quantidade de itens nem cursor suficiente para paginação contínua; por isso o status permanece PARCIAL.
