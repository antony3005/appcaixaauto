# Gaps de backend — App 24/7 Cliente

Data: 2026-09-30  
Status geral: frontend preparado; backend cliente incompleto.

Cada seção distingue contratos executáveis já integrados de sugestões ainda pendentes. Rotas marcadas como disponíveis são chamadas pelo aplicativo; as demais não devem ser tratadas como API existente.

## Cadastro de cliente

**Status: DISPONÍVEL E INTEGRADO EM 30/09/2026**

### Contrato executável

Rota real:

```http
POST /auth/register
Content-Type: application/json
```

```json
{
  "nome": "Maria",
  "sobrenome": "da Silva",
  "cpf": "52998224725",
  "email": "maria@email.com",
  "telefone": "75999999999",
  "senha": "<senha em trânsito HTTPS>",
  "termsAccepted": true,
  "privacyAccepted": true,
  "termsVersion": "<versão publicada>",
  "privacyVersion": "<versão publicada>"
}
```

Regras confirmadas:

- `nome`, `sobrenome`, `cpf`, `email` e `senha` obrigatórios;
- `telefone` opcional enquanto assim permanecer no domínio;
- senha com mínimo de 6 caracteres;
- CPF com 11 dígitos e dígitos verificadores válidos;
- normalização e unicidade definitivas no backend;
- papel imposto como `USER` pelo backend;
- request não aceita `roleUser`, `empresaId`, `condominioId`, saldo, pontos ou cashback;
- endpoint público na autenticação, com rate limiting e proteção contra abuso;
- senha persistida somente com BCrypt, como já ocorre em `salvarNovoUsuario`;
- `RegistrationService` não usa `EmpresaContext` e cria `User` global com Empresa/Condomínio nulos;
- CPF nasce não verificado e o cadastro não executa claim de compras antigas.

Resposta real, que não emite token no cadastro:

```http
HTTP/1.1 201 Created
```

```json
{
  "user": { "id": "...", "nome": "Maria da Silva", "email": "maria@email.com" },
  "cpfVerificationStatus": "UNVERIFIED",
  "condominio": null,
  "requiresLogin": true,
  "legalDocumentsConfigured": false
}
```

Erros necessários:

| HTTP | `code` | Mensagem de UI |
|---|---|---|
| 400 | `INVALID_CPF` | Confira o CPF informado. |
| 400 | `INVALID_REGISTRATION_DATA` | Revise os dados informados. |
| 409 | `CPF_ALREADY_REGISTERED` | Já existe uma conta cadastrada com este CPF. |
| 409 | `EMAIL_ALREADY_REGISTERED` | Este e-mail já está sendo utilizado. |

`INVALID_REGISTRATION_DATA` mantém `fieldErrors` no formato de `RestErrorMessage`. A migration V16 tornou `users.empresa_id` anulável; o vínculo posterior usa o convite opaco de `POST /app-cliente/tenant-link`, sem UUID arbitrário no cliente.

O Flutter consulta `GET /public/app-config`. Quando os documentos estão
configurados, mostra seus links e versões e somente habilita o cadastro após os
dois aceites. Quando não estão, os campos legais são omitidos para preservar o
contrato operacional existente.

## Vínculo da conta global

**Status: DISPONÍVEL E INTEGRADO EM 30/09/2026**

No estado `TENANT_LINK_REQUIRED`, o app aceita o convite opaco e chama
`POST /app-cliente/tenant-link` com body contendo somente `token`. O novo JWT da
resposta substitui a sessão global em memória, seguido de novo bootstrap. O app
não oferece seletores de Empresa/Condomínio e não persiste o convite.

## Bootstrap e configurações remotas

**Status:** DISPONÍVEL E INTEGRADO EM 30/09/2026  
**Dados necessários:** usuário autenticado, Condomínio atual, capacidades/feature flags e modo de fidelidade.  
**Endpoint sugerido:** `GET /app-cliente/bootstrap`  
**Request:** JWT do usuário, sem IDs autoritativos no query/body.  
**Response sugerida:** `user`, `condominio`, `features { catalogo, promocoes, fidelidade, pontos, cashback, recompensas, cupons, qrIdentificacao, preferencias, suporte }`, `loyaltyMode`.  
**Motivo:** `UserResponseDTO` omite `condominio`; não existe configuração cliente. Sem isso a UI oculta recursos opcionais.

## Catálogo e promoções do Condomínio

**Status:** PARCIAL NO BACKEND / INDISPONÍVEL AO APP  
**Dados necessários:** produtos autorizados no Condomínio, foto, categoria, unidade, preço original, preço final e promoção já calculada.  
**Endpoint sugerido:** `GET /app-cliente/catalogo?busca=&categoria=&page=&size=` derivando usuário e Condomínio do JWT.  
**Response sugerida:** página de `ProdutoTerminalResponse` sem quantidade física sensível.  
**Motivo:** `/terminais/{terminalId}/produtos-disponiveis` tem os dados corretos, mas o cliente não recebe terminal/Condomínio e não deve escolher tenant localmente.

## Detalhe de compra e comprovante

**Status:** PARCIAL  
**Dados necessários:** Order autorizada pelo usuário, Condomínio/local, snapshots dos itens, quantidades, totais, pagamento, status, benefício gerado, `receiptAvailable` e ações disponíveis.  
**Endpoint sugerido:** `GET /app-cliente/compras/{orderId}`.  
**Request:** JWT; backend verifica `Order.user`.  
**Response sugerida:** snapshot completo sem `remoteOrderId`, UUID técnico visível ou credenciais.  
**Motivo:** histórico atual é resumido e `/order` busca por `carrinho_id`; `POST /comprovante` exige `terminalId`, não fornecido no histórico.

## Visualização e compartilhamento de comprovante

**Status:** AUSENTE/PARCIAL  
**Dados necessários:** URL/bytes oficiais temporários e canais permitidos.  
**Endpoints sugeridos:** `GET /app-cliente/compras/{orderId}/comprovante` e `POST /app-cliente/compras/{orderId}/comprovante/envios`.  
**Request de envio:** `{ "canal": "EMAIL|WHATSAPP", "destinatario": "..." }`.  
**Response sugerida:** `{ "status": "ACCEPTED|ALREADY_ACCEPTED" }`.  
**Motivo:** o app não deve gerar documento financeiro localmente nem fornecer `terminalId` como autoridade.

## QR de identificação no Terminal

**Status:** DISPONÍVEL E INTEGRADO EM 30/09/2026  
**Dados necessários:** token opaco, uso único, expiração absoluta e tempo de servidor.  
**Endpoint real:** `POST /app-cliente/identificacao-tokens`.  
**Request:** JWT, body vazio.  
**Response real:** `{ "qrPayload": "app247://customer-link/<opaque>", "expiresAt": "...", "serverTime": "..." }`.  
**Implementação:** `ClientApiRepository` preserva o payload do backend e
`CustomerIdentificationPage` o renderiza sem persistência ou logs.

## Fidelidade, pontos e cashback

**Status:** AUSENTE  
**Dados necessários:** programa ativo, modo efetivo, saldos autoritativos, expiração, movimentos e progresso já calculado.  
**Endpoint sugerido:** `GET /app-cliente/fidelidade`.  
**Request:** JWT.  
**Response sugerida:** `{ "enabled": true, "mode": "POINTS|CASHBACK", "balance": ..., "movements": [...], "nextReward": ... }`.  
**Motivo:** não existem entidades/rotas cliente; o Flutter não pode somar movimentos nem decidir coexistência.

## Recompensas e resgate

**Status:** AUSENTE  
**Dados necessários:** recompensa ativa/elegível, custo, benefício, compra mínima, desconto máximo, validade e motivo de indisponibilidade.  
**Endpoints sugeridos:** `GET /app-cliente/recompensas` e `POST /app-cliente/recompensas/{id}/resgates` com `Idempotency-Key`.  
**Request de resgate:** body vazio ou versão esperada do programa.  
**Response sugerida:** saldo atualizado e cupom emitido.  
**Motivo:** resgate precisa ser atômico, autoritativo e resistente a duplo clique/repetição de rede.

## Cupons e QR de cupom

**Status:** AUSENTE  
**Dados necessários:** benefício, compra mínima, desconto máximo, validade, status amigável e elegibilidade.  
**Endpoints sugeridos:** `GET /app-cliente/cupons` e `POST /app-cliente/cupons/{id}/tokens`.  
**Response do token sugerida:** `{ "token": "opaque", "expiresAt": "...", "serverTime": "..." }`.  
**Motivo:** app não conhece carrinho e não pode embutir desconto no QR; backend/Terminal validam uso e consumo.

## Preferências de comprovante

**Status:** AUSENTE  
**Dados necessários:** salvar no app, autoenvio por e-mail/WhatsApp e canais permitidos/verificados.  
**Endpoints sugeridos:** `GET/PUT /app-cliente/preferencias`.  
**Motivo:** autoenvio não pode ser prometido sem persistência e suporte operacional.

## Suporte vinculado à compra

**Status:** AUSENTE  
**Dados necessários:** categorias permitidas, mensagem, anexos opcionais e referência de Order derivada/validada.  
**Endpoint sugerido:** `POST /app-cliente/compras/{orderId}/suporte`.  
**Request sugerida:** `{ "categoria": "...", "mensagem": "..." }`.  
**Response sugerida:** protocolo amigável.  
**Motivo:** usuário não deve copiar UUID e o backend precisa autorizar a relação com a compra.

## Segurança de rotas existentes

**Status:** REVISAR ANTES DE PRODUÇÃO  
`SecurityConfig` ainda deixa rotas residuais em `permitAll`; `/user/{userId}` e `/user/{userId}/orders` aceitam ID no caminho. Criar APIs cliente que derivem `userId`/Empresa/Condomínio do principal autenticado e autorizem cada recurso.
