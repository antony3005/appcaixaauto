# APP247 Client — Relatório final

Data: **03/10/2026**

## Skill e Figma

A `impeccable-flutter` foi reaplicada a partir do app executado e das capturas reais: contexto/product, fundamentos Flutter, composição, tokens, reflow, estados, touch targets e inspeção dos screenshots. O MCP oficial do Figma foi chamado novamente, mas o plano Starter estava no limite; esta revisão usa os oito node IDs já documentados e registra a limitação, sem alegar uma nova leitura. Veja `docs/figma-adaptation.md` e `docs/visual-redesign-verification.md`.

## Design System e tema

- Primary `#082F5B`; dark background `#031B35`; light `#F7F9FC`; gold `#C89B3C`.
- Tipografia M3 12–34 px; spacing 4/8/12/16/24/32/48; radius 10/14/20/28/pill.
- Componentes compartilhados para conteúdo, cards, headers, estados, badges, produto e compra.

| Tema | Resultado |
|---|---|
| Light | PASS |
| Dark | PASS |
| System | PASS |

## Telas

| Tela | Antes | Depois | Backend |
|---|---|---|---|
| Login | Parcial | Completa + sessão/recuperação | login + `/user/*` |
| Cadastro | Completa | Redesign preservado | public config/register |
| Tenant Link | Parcial | Colagem, erros, JWT persistido | tenant-link |
| Home | Parcial | Hero de identidade, QR, fidelidade e atalhos por flags | bootstrap e features |
| Meu QR | Completa | Redesign sem regressão | identification token |
| Catálogo/Produto | Vazio | Busca, filtro, paginação, detalhe | catálogo |
| Compras/Detalhe | Parcial/placeholder | Resumo real, paginação, itens e totais | compras/detalhe |
| Comprovante/Suporte | Ausentes | PNG, zoom/share/envio e protocolo | receipt/send/support |
| Benefícios | Layout | Extrato, rewards premium, destinos focados, resgate e cupons | fidelity/rewards/coupons |
| QR cupom | Quebrado | Token com `serverTime` | coupon tokens |
| Perfil/Preferências | Parcial/fixo | Hero de identidade, dados, tema, legal e GET/PUT | bootstrap/preferences |

## Implementações e stubs removidos

JWT seguro/restaurado, 401 global, recuperação, Tenant Link, catálogo remoto, compra paginada/detalhada, PNG binário, suporte, fidelidade `NONE/POINTS/CASHBACK`, extrato, resgate idempotente, cinco estados de cupom, QR e preferências. Foram removidos detalhe placeholder, catálogo vazio, comprovante desabilitado, resgate/QR stubs, preferências fixas, flags fictícias e ngrok default.

## Sessão, catálogo, compras e benefícios

- Secure storage/restart/401/logout: PASS.
- Catálogo paginação/busca/categoria/promoção: PASS.
- Compras lista/paginação/detalhe/comprovante/suporte: PASS.
- Loyalty/movements/rewards/redemption/coupons/coupon QR: PASS.

Os 22 endpoints estão listados no gap report; os 18 principais originalmente auditados ficaram com **0 gaps de integração**.

## Testes

| Validação | Resultado |
|---|---|
| `dart format .` | PASS — 44 arquivos |
| `flutter analyze` | PASS — 0 issues |
| `flutter test` | PASS — 87 testes |
| `flutter build apk --debug` | PASS — `build/app/outputs/flutter-apk/app-debug.apk` |
| backend local | indisponível em `localhost:8080`; backend não foi alterado |

Novos testes cobrem contratos Spring, PNG binário, sessão/restart, 401, idempotência estável e a matriz real de navegação das telas principais em light/dark.

## Goldens

Após inspeção visual, foram atualizados `home-360x800`, `home-390x844-text-130`, `home-430x932` e `registration-390x844` devido ao novo tema, superfícies e spacing. Não havia overflow ou ação crítica recortada.

As evidências em `docs/screenshots/` também foram regeneradas após detectar que
`light/cupons.png` estava vazio e que frames de rotas anteriores podiam aparecer
em capturas subsequentes. O teste agora desmonta a tela anterior entre registros;
Cupons e Recompensas usam exatamente os destinos focados abertos pela Home.

## Arquivos alterados

- `pubspec.yaml`, `pubspec.lock`, `lib/main.dart`, `lib/src/app.dart`
- `lib/src/core/{config,theme}`, `lib/src/data`, `lib/src/domain`, `lib/src/state`
- `lib/src/features/{auth,home,catalog,purchases,benefits,profile,qr,shell}`
- `lib/src/shared/app_widgets.dart`
- fixtures/testes em `test/`, quatro goldens e documentação em `docs/`

O working tree já continha mudanças e arquivos não rastreados; nada alheio foi resetado ou limpo.

## Backend alterado

**Nenhuma alteração backend necessária.** O Flutter foi adaptado ao contrato real.

## Gap final e pendências

- completas: **17**; parciais: **0**; ausentes: **0**; endpoints principais sem integração: **0**.
- **P0:** nenhuma.
- **P1:** QA físico de compartilhamento e intents de e-mail/WhatsApp.
- **P2:** formalizar universal/app link do convite; não foi inventado esquema sem contrato.
