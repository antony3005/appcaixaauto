---
status: PARCIAL
ultima_revisao: 2026-09-14
---
# Comprovantes

Voltar para [[index-00-app-cliente]] e [[31-detalhe-compra]].

O backend possui `POST /comprovante`, mas exige `terminalId`, `pedidoId`, `tipoEnvio` e destinatário. O histórico cliente não fornece `terminalId` nem contrato de visualização. A ação permanece oculta/desabilitada por capability; o app não gera comprovante local, não altera status da compra e não chama FastAPI/n8n diretamente.
