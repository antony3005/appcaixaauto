---
status: IMPLEMENTADO
ultima_revisao: 2026-09-30
---
# QR de identificação no Terminal

Voltar para [[index-00-app-cliente]]. Relacionada a [[61-qr-token]] e [[46-regras-elegibilidade]].

`CustomerIdentificationPage` e `CustomerIdentificationController` cobrem geração
automática, loading, erro/offline, contagem regressiva, background, expiração e
nova geração. `QrImageView` recebe somente `CustomerIdentificationToken.qrPayload`;
CPF, JWT, userId, tenant, saldo e desconto nunca entram no QR nem em logs.

O repository de produção usa o endpoint real
`POST /app-cliente/identificacao-tokens`, com JWT da `AuthSession`, body vazio e
response `qrPayload + expiresAt + serverTime`. O acesso aparece na Home e no Perfil
quando `GET /app-cliente/bootstrap` informa `features.qrIdentificacao=true`.

Detalhes executáveis e roteiro de testes em
`docs/customer-identification-qr.md`.
