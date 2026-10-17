# Meu QR — identificação do cliente no Terminal

## Contrato

O App Cliente autenticado executa:

```http
POST /app-cliente/identificacao-tokens
Authorization: Bearer <JWT da sessão atual>
```

O request não possui body. HTTP `201 Created` retorna:

```json
{
  "qrPayload": "app247://customer-link/<opaco>",
  "expiresAt": "2026-09-30T13:02:00Z",
  "serverTime": "2026-09-30T13:00:00Z"
}
```

O Flutter renderiza `qrPayload` sem montar, concatenar ou interpretar identidade.
CPF, `userId`, JWT, Empresa, Condomínio, pontos e cashback não entram no QR. O
payload não é impresso em log nem salvo em storage, SQLite ou preferências.

O TTL padrão atual do backend é 120 segundos, configurável no Spring. O app usa
`expiresAt` e `serverTime` recebidos para exibir o countdown; a decisão definitiva
de expiração e uso único continua sendo do backend.

## Arquitetura

```text
CustomerIdentificationPage
        ↓ observa
CustomerIdentificationController (ChangeNotifier + Timer)
        ↓
ClientRepository
        ↓
ClientApiRepository / package:http
        ↓ Authorization: Bearer <JWT da AuthSession>
POST /app-cliente/identificacao-tokens
```

`CustomerIdentificationController` impede chamadas simultâneas, invalida respostas
assíncronas após `dispose`, cancela o timer e descarta o payload ao expirar. Ao
retornar do background, a tela recalcula a validade imediatamente usando a hora
estimada do servidor; ela não depende de ticks ocorridos enquanto suspensa.

## Estados

```text
INITIAL → LOADING → VALID → EXPIRED
              ↑                ↓
              └── GERAR NOVO ──┘

LOADING → ERROR/OFFLINE → TENTAR NOVAMENTE → LOADING
```

- `LOADING`: “Gerando seu QR...” e botão desabilitado;
- `VALID`: QR estático em superfície branca, countdown e opção de gerar outro;
- `EXPIRED`: payload removido da árvore e ação “GERAR NOVO QR”;
- `ERROR`: mensagem segura para HTTP, timeout ou resposta inválida;
- `OFFLINE`: instrução explícita para reconectar.

Erros reais tratados: `AUTH_REQUIRED`, `TENANT_LINK_REQUIRED`,
`CONDOMINIUM_REQUIRED`, `TENANT_MISMATCH` e `CUSTOMER_QR_DISABLED`. Detalhes
técnicos do servidor não são exibidos.

## UX e acessibilidade

O acesso “Meu QR” aparece na Home e no Perfil quando `features.qrIdentificacao`
do `GET /app-cliente/bootstrap` está ativo. O texto de benefício usa
`loyaltyMode=POINTS|CASHBACK|NONE`. O QR possui semântica de imagem, alto contraste,
margem clara, módulos pretos, nenhum logo central e tamanho adaptado às constraints.

## Como testar

```bash
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

Os testes cobrem parsing, autenticação HTTP, erros 400/401/403/500, timeout,
offline, duplo clique, substituição do QR, expiração, background, descarte seguro,
estados do widget e viewports 320×568, 430×932 e 800×1280.
