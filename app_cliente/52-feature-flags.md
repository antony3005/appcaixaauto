---
status: PARCIAL
ultima_revisao: 2026-09-14
---
# Feature flags

Voltar para [[index-00-app-cliente]], [[20-home]] e [[40-fidelidade-visao-geral]].

`ClientCapabilities` controla catálogo, promoções, QR de identificação, fidelidade, modo pontos/cashback, recompensas, cupons, QR de cupom, comprovantes, preferências e suporte. A navegação e seções são reconstruídas sem lacunas quando flags estão desligadas. O backend ainda não entrega essas flags; o adapter de produção usa defaults seguros `false`, e os estados completos são exercitados apenas por fixtures em `test/`.
