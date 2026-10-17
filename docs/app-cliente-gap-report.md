# APP CLIENTE — GAP REPORT FINAL

Atualizado em **01/10/2026** após o redesign e a integração do App Cliente com os contratos executáveis do backend Spring.

Regra preservada: **o App identifica, informa e recompensa; o Terminal vende**. Não existem carrinho, checkout, pagamento mobile, Mercado Pago ou controle da Point no App Cliente.

| Indicador | Antes | Depois |
|---|---:|---:|
| Telas/experiências completas | 2 | 17 |
| Telas parciais | 7 | 0 |
| Placeholders | 1 | 0 |
| Telas quebradas/inacessíveis | 1 | 0 |
| Experiências relevantes ausentes | 5 | 0 |
| Endpoints principais sem integração completa | 12 | 0 |

As 17 experiências são: Login, Cadastro, Recuperação, Tenant Link, Home, Meu QR, Catálogo, Produto, Histórico, Detalhe da compra, Comprovante/envio, Suporte, Benefícios/Extrato, Recompensas/Resgate, Cupons/QR, Perfil e Preferências/Tema.

## Estado final

| Área | Resultado |
|---|---|
| Sessão | JWT em secure storage, restauração, 401 global e logout |
| Recuperação | CPF → código → nova senha → sucesso |
| Tenant Link | Convite opaco, colagem, novo JWT persistido e bootstrap |
| Home | Flags reais, QR, catálogo/promoções, saldo e compras recentes |
| Catálogo | Busca, categoria, paginação, promoção e detalhe informativo |
| Compras | Paginação, detalhe, PNG binário, envio e suporte |
| Benefícios | `NONE/POINTS/CASHBACK`, movimentos, resgate, cupons e QR |
| Perfil | Dados reais, preferências, tema, legal e logout |

## Endpoints integrados

- `GET /public/app-config`; `POST /auth/register`; `POST /auth/login`
- `POST /user/recuperar`; `POST /user/validar`; `POST /user/redefinir-senha`
- `POST /app-cliente/tenant-link`; `GET /app-cliente/bootstrap`
- `GET /app-cliente/catalogo`
- `GET /app-cliente/compras`; `GET /app-cliente/compras/{orderId}`
- `GET /app-cliente/compras/{orderId}/comprovante`
- `POST /app-cliente/compras/{orderId}/comprovante/envios`
- `POST /app-cliente/compras/{orderId}/suporte`
- `POST /app-cliente/identificacao-tokens`
- `GET /app-cliente/fidelidade`; `GET /app-cliente/recompensas`
- `POST /app-cliente/recompensas/{id}/resgates`
- `GET /app-cliente/cupons`; `POST /app-cliente/cupons/{id}/tokens`
- `GET /app-cliente/preferencias`; `PUT /app-cliente/preferencias`

## Removidos

Detalhe placeholder, catálogo vazio, resgate/QR de cupom indisponíveis, comprovante desabilitado, preferências fixas, flags fictícias `couponQr`, `receipts` e `catalogSearchIsComplete`, e fallback silencioso para ngrok.

## Verificação

| Comando | Resultado |
|---|---|
| `flutter pub get` | PASS |
| `dart format .` | PASS — 43 arquivos |
| `flutter analyze` | PASS — 0 issues |
| `flutter test` | PASS — 82 testes |
| `flutter build apk --debug` | PASS |
| `IDENTITY_HASH_SECRET=<teste> ./mvnw test` | PASS — 415 testes; 22 migrations |

## Pendências

- **P0:** nenhuma.
- **P1:** QA físico do compartilhamento do PNG e apps de e-mail/WhatsApp.
- **P2:** definir contrato universal/app link do convite de tenant. A colagem assistida cobre com segurança o contrato atual.

