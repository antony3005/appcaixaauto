---
status: PARCIAL
ultima_revisao: 2026-09-14
---
# Recompensas

Voltar para [[index-00-app-cliente]], [[40-fidelidade-visao-geral]] e [[44-cupons]].

`RewardSummary`/`_RewardCard` mostram benefício, custo, compra mínima e desconto máximo. A confirmação repete as condições, bloqueia duplo clique com `redeemingRewardId` e diferencia “Resgatando...”. O repository de produção não inventa rota e responde indisponibilidade até o backend implementar resgate atômico/idempotente.
