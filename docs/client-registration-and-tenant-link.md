# Cadastro, documentos legais e vínculo ao tenant

## Cadastro público

Antes de habilitar o envio, a tela consulta:

```http
GET /public/app-config
```

Quando `legalDocumentsConfigured=true`, o app mostra links HTTPS para os Termos
de Uso e para a Política de Privacidade, com suas versões, e exige os dois
aceites. O cadastro envia as versões recebidas do backend; elas nunca são
inventadas ou fixadas no Flutter.

```http
POST /auth/register
Content-Type: application/json
```

Além dos dados pessoais, os campos condicionais são `termsAccepted`,
`privacyAccepted`, `termsVersion` e `privacyVersion`. O request nunca contém
`empresaId`, `condominioId` ou `role`. Se os documentos não estiverem
configurados no backend, esses quatro campos são omitidos e o cadastro segue o
contrato compatível existente.

Falha ao carregar a configuração legal bloqueia o envio e oferece retry. A tela
protege contra duplo envio e descarta callbacks assíncronos depois de `dispose`.

## Conta global e convite

Após cadastro e login, uma conta global pode receber
`TENANT_LINK_REQUIRED`. Nesse estado, o app solicita apenas o convite opaco
fornecido pelo gestor e chama:

```http
POST /app-cliente/tenant-link
Authorization: Bearer <JWT global>
Content-Type: application/json

{ "token": "<convite opaco>" }
```

O Flutter não envia CPF, Empresa ou Condomínio. Em `status=LINKED`, substitui a
sessão em memória pelo `accessToken` devolvido e recarrega o bootstrap. O token
do convite não é salvo em storage, preferências ou SQLite; o campo é limpo após
sucesso e não existe logging do seu conteúdo.

`TENANT_INVITATION_INVALID` é exibido de forma opaca, sem revelar tenant ou CPF.
Enquanto a chamada está em andamento, campo e botão ficam desabilitados para
evitar consumo duplicado.

## Estados e testes

- configuração legal: loading, pronta sem documentos, pronta com documentos e
  erro com retry;
- cadastro: validação, envio, sucesso e erro;
- vínculo: aguardando convite, vinculando, erro e bootstrap autenticado;
- telas usam rolagem, labels nativos e regiões semânticas para erros;
- testes HTTP garantem que IDs de tenant/role não entram nos requests;
- testes de widget cobrem aceite obrigatório, duplo toque, erro opaco e texto
  ampliado.
