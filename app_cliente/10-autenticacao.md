---
status: IMPLEMENTADO — CADASTRO PÚBLICO INTEGRADO
ultima_revisao: 2026-09-30
---
# Autenticação

Voltar para [[index-00-app-cliente]] e [[11-perfil-cliente]].

`LoginPage` envia CPF sem máscara e senha para o contrato real `POST /auth/login` por `ClientApiRepository`. O token permanece apenas em memória durante esta etapa e nunca é registrado. Há validação, estado de envio bloqueado, erro amigável e autofill.

## Navegação

```text
Splash/AuthGate
  -> Login
       |-> Criar conta -> Cadastro
       `-> Entrar -> Home
```

O Login mostra explicitamente `Ainda não tem uma conta?` e `CRIAR CONTA`. `RegistrationPage` é aberta por `MaterialPageRoute` e não substitui o AuthGate: usuário com sessão ativa continua indo para `ClientShell`.

## Cadastro implementado no Flutter

A tela usa o fluxo arquitetural:

```text
RegistrationPage
  -> RegistrationController
       -> ClientRepository.registerClient
            -> ClientApiRepository
```

Não há HTTP no widget. O controller representa `idle`, `validating`, `submitting`, `success` e `error`, adquire o bloqueio antes de qualquer `await` e impede request concorrente. A senha existe apenas nos controllers de texto e no request em memória; não é persistida nem registrada.

### Campos reais

Os campos vêm de `ClientRegistrationRequest`, auditado no backend. O formulário apresenta:

| UI | Campo de contrato | Regra |
|---|---|---|
| Nome completo | `nome` + `sobrenome` | trim, espaços normalizados, ambos obrigatórios, limite compatível com as colunas de 100 caracteres |
| CPF | `cpf` | máscara `000.000.000-00`, somente 11 dígitos no request e validação dos dígitos verificadores |
| E-mail | `email` | obrigatório e formato básico local |
| WhatsApp / telefone | `telefone` | opcional no DTO atual, máscara pt-BR e envio somente de dígitos |
| Senha | `senha` | mínimo de 6 caracteres, exatamente como `@Size(min = 6)` |
| Confirmar senha | somente Flutter | deve ser idêntica; não é enviada |

`role`, `roleUser`, `empresaId` e `condominioId` não aparecem no request do app; o backend impõe `USER` e cria Empresa/Condomínio nulos.

Não foram adicionados aceite nem links de Termos/Privacidade porque não há documentos ou URLs reais no projeto.

## Endpoint auditado

**Cadastro de cliente — Status: DISPONÍVEL E INTEGRADO.**

`ClientApiRepository.registerClient` chama `POST /auth/register` sem JWT. O endpoint é público, possui rate limit por IP/e-mail/CPF e usa `RegistrationService`, que não depende de `EmpresaContext`. A resposta é `201 ClientRegistrationResponse` com `requiresLogin = true`; por isso o app confirma o cadastro e volta ao Login, sem inventar autenticação automática.

O backend normaliza CPF/e-mail/telefone, valida os dígitos verificadores do CPF, aplica BCrypt, força role `USER`, deixa `cpfVerifiedAt`, Empresa e Condomínio nulos e não executa claim histórico. O vínculo posterior ocorre exclusivamente pelo convite opaco de `POST /app-cliente/tenant-link`.

## Erros e sucesso

O estado aceita erros tipados e nunca exibe status HTTP, exceção SQL ou stack trace. A UI cobre:

- CPF já cadastrado: `Já existe uma conta cadastrada com este CPF.` e ação `IR PARA LOGIN`;
- e-mail já cadastrado: mensagem amigável no campo/fluxo;
- CPF inválido: erro inline, sem request;
- `INVALID_REGISTRATION_DATA`: `fieldErrors` volta aos campos correspondentes;
- `REGISTRATION_RATE_LIMITED`: orienta tentar novamente mais tarde;
- timeout/offline/5xx: mensagens recuperáveis sem detalhes técnicos.

Quando o repositório confirma criação, a tela mostra `Cadastro concluído` e volta para Login. Não há login automático nem JWT inventado porque o endpoint legado não devolve autenticação.

## Limites de domínio preservados

- CPF informado no Terminal não cria conta.
- O Flutter não procura compras antigas comparando CPF; ownership e eventual histórico anterior pertencem ao backend.
- Criar conta não concede pontos, cashback ou cupom.
- Identificação posterior continua separada em `POST /app-cliente/identificacao-tokens`.
- Perfil e vínculo de Condomínio continuam autoritativos no backend.

## Verificação

Há testes de abertura pelo Login, formulário vazio, CPF inválido/válido, e-mail inválido, senha curta, confirmação diferente, loading, falha, CPF duplicado, sucesso, duplo clique e volta ao Login. O layout rolável foi testado com teclado simulado em 360×800, 390×844 e 430×932.

## Conta ainda sem tenant

O login da conta global é válido e emite JWT sem `empresaId`. Quando o bootstrap responde `TENANT_LINK_REQUIRED` ou `CONDOMINIUM_REQUIRED`, o `ClientShell` mostra um estado explícito com instrução para usar o convite do estabelecimento/administrador, ação de reconsulta e logout. Não há dropdown ou escolha livre de Empresa/Condomínio.

## Pendências

- integrar no Flutter a captura/consumo do convite de `POST /app-cliente/tenant-link`;
- decidir sessão persistente segura do App Cliente;
- publicar Termos de Uso e Política de Privacidade reais antes de ativar aceites obrigatórios.
