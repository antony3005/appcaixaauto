---
title: "App 24/7 Cliente — INDEX-00"
aliases:
  - "INDEX-00"
  - "Índice App Cliente"
  - "Mapa App 24/7 Cliente"
tags:
  - app247
  - cliente
  - flutter
  - obsidian
  - codex
  - index
status: ativo
tipo: indice-mestre
ultima_revisao: 2026-09-25
---

# App 24/7 Cliente — INDEX-00

> [!important]
> Este arquivo é o **ponto de entrada obrigatório** da documentação do projeto **App 24/7 Cliente** no Obsidian.
>
> O Codex deve ler este arquivo antes de implementar, alterar, refatorar ou documentar qualquer funcionalidade deste aplicativo.
>
> **Escopo deste vault: somente o aplicativo do cliente.**
>
> Backend, Terminal, painel do gestor, Mercado Pago, FastAPI e n8n aparecem aqui apenas como dependências/integrações necessárias para compreender o App Cliente. Eles não fazem parte do escopo de implementação deste projeto, salvo quando a tarefa disser explicitamente o contrário.

---

# 1. Papel do App 24/7 Cliente

O aplicativo do cliente é uma camada de relacionamento, identificação, histórico e fidelidade.

Ele deve permitir ao cliente:

- identificar-se no Terminal por QR Code;
- visualizar o Condomínio vinculado;
- visualizar produtos disponíveis naquele Condomínio;
- visualizar promoções em destaque;
- consultar histórico de compras;
- abrir detalhes de uma compra;
- visualizar e reenviar comprovantes;
- acompanhar pontos ou cashback quando o programa estiver habilitado;
- consultar recompensas;
- resgatar cupons;
- gerar QR temporário para usar cupom no Terminal;
- configurar dados pessoais e preferências;
- acessar suporte relacionado a uma compra.

> [!danger]
> O App Cliente **não realiza compras**.

O aplicativo não deve:

- montar carrinho;
- adicionar produto para compra;
- criar Order;
- iniciar checkout;
- iniciar pagamento;
- pagar pelo celular;
- chamar Mercado Pago;
- substituir o Terminal;
- substituir a Point.

Regra central:

> **O app identifica, informa e recompensa. O Terminal vende.**

---

# 2. Regra para o Codex

Antes de trabalhar em qualquer tarefa:

1. Leia `INDEX-00.md`.
2. Identifique a nota específica da funcionalidade.
3. Leia as notas relacionadas por `[[wikilinks]]`.
4. Inspecione o código real antes de assumir nomes de classes, rotas, models ou endpoints.
5. Não invente funcionalidades que não estejam implementadas no backend.
6. Não coloque regra financeira ou de fidelidade autoritativa no Flutter.
7. Não transforme o App Cliente em checkout.
8. Não implemente telas de gestor dentro deste projeto.
9. Quando uma feature depender de configuração do gestor, o app apenas **consome e respeita** a configuração recebida.
10. Atualize a documentação da feature quando o código for alterado.

---

# 3. Fonte de verdade do domínio

O App Cliente deve tratar o backend como fonte de verdade para:

- usuário autenticado;
- Condomínio vinculado;
- catálogo disponível;
- preços;
- promoções;
- histórico de compras;
- status das compras;
- comprovantes;
- pontos;
- cashback;
- cupons;
- elegibilidade;
- valor mínimo para uso de cupom;
- saldo;
- validade;
- configurações habilitadas/desabilitadas pelo gestor.

O Flutter não deve recalcular regras comerciais.

---

# 4. Estrutura de documentação do projeto

## Base

- [[01-visao-geral]]
- [[02-arquitetura-app-cliente]]
- [[03-navegacao]]
- [[04-design-system]]
- [[05-estados-ui]]

## Autenticação e identidade

- [[10-autenticacao]] — Login, Criar conta, campos/validações reais, estados, sucesso e gap de backend do cadastro.
- [[11-perfil-cliente]]
- [[12-condominio-vinculado]]
- [[13-qr-identificacao-terminal]]
- [[14-cpf-e-historico-anterior]]

## Home e catálogo

- [[20-home]]
- [[21-produtos-condominio]]
- [[22-produto-detalhe]]
- [[23-promocoes]]
- [[24-busca-e-filtros]]

## Compras e comprovantes

- [[30-historico-compras]]
- [[31-detalhe-compra]]
- [[32-comprovantes]]
- [[33-suporte-compra]]

## Fidelidade

- [[40-fidelidade-visao-geral]]
- [[41-pontos]]
- [[42-cashback]]
- [[43-recompensas]]
- [[44-cupons]]
- [[45-qr-cupom-terminal]]
- [[46-regras-elegibilidade]]

## Configurações

- [[50-preferencias]]
- [[51-configuracoes-remotas]]
- [[52-feature-flags]]

## Segurança

- [[60-seguranca]]
- [[61-qr-token]]
- [[62-privacidade]]

## Projeto

- [[90-roadmap]]
- [[91-pendencias]]
- [[92-decisoes-abertas]]

> [!note]
> Nem todas as notas precisam existir agora. Criá-las conforme as funcionalidades forem trabalhadas.

---

# 5. Navegação principal sugerida

A estrutura inicial do app pode seguir:

```text
HOME
├── Promoções
├── Produtos do Condomínio
├── Fidelidade
└── Últimas compras

COMPRAS
├── Histórico
├── Detalhe
└── Comprovante

BENEFÍCIOS
├── Pontos ou Cashback
├── Recompensas
└── Cupons

PERFIL
├── Dados pessoais
├── Condomínio
├── Preferências
└── Identificação no Terminal
```

A navegação final deve respeitar a arquitetura já existente no projeto.

---

# 6. Home

A Home é contextual ao Condomínio vinculado ao cliente.

Estrutura conceitual:

```text
Olá, <nome>

<Condomínio atual>

OFERTAS EM DESTAQUE
[ produto ] [ produto ] [ produto ]

FIDELIDADE
[ saldo / progresso / cupom ]
(apenas se habilitado)

PRODUTOS DO SEU MERCADO
[ busca ]
[ categorias ]
[ produtos ]

ÚLTIMAS COMPRAS
[ compra ]
[ compra ]
```

A Home deve priorizar:

1. promoções;
2. produtos do Condomínio;
3. benefícios ativos;
4. histórico recente.

---

# 7. Produtos do Condomínio

O app deve mostrar somente produtos disponibilizados para o Condomínio atual segundo o backend.

Conceitualmente:

```text
Condomínio atual
↓
catálogo autorizado pelo backend
↓
produtos exibidos no app
```

Não assumir que todo produto da Empresa está disponível naquele Condomínio.

O card pode mostrar:

- foto;
- nome;
- categoria;
- preço;
- preço promocional quando houver;
- unidade/quantidade de referência quando fizer sentido.

Não mostrar:

- botão Comprar;
- botão Adicionar ao carrinho;
- botão Pagar.

Pode existir:

```text
Ver detalhes
```

sem iniciar compra.

---

# 8. Promoções

Produtos em promoção devem receber destaque visual.

Exemplo conceitual:

```text
OFERTAS

Coca-Cola 2L
De R$ 10,99
Por R$ 8,99
```

O backend entrega a promoção válida.

O app não deve calcular:

- percentual;
- desconto fixo;
- preço fixo;
- prioridade;
- cumulatividade.

---

# 9. Identificação no Terminal

O cliente que possui o app pode gerar um QR temporário para identificar sua compra no Terminal.

Fluxo:

```text
App
↓
Identificar no Terminal
↓
backend gera token temporário
↓
app mostra QR
↓
scanner lê
↓
Terminal envia token ao backend
↓
backend vincula a sessão/Order ao usuário
```

O QR não deve conter diretamente:

- CPF;
- senha;
- JWT;
- total da compra;
- descontos;
- saldo;
- userId confiável;
- regras de negócio.

Preferir token:

- opaco;
- temporário;
- de uso único;
- com curta validade.

---

# 10. Pessoa sem app no momento da compra

O Terminal pode pedir CPF para salvar a compra para histórico futuro.

Isso **não pertence ao fluxo de criação de conta deste app**.

Regra importante:

```text
CPF informado no Terminal
↓
compra fica associada a uma identidade futura
↓
nenhuma conta é criada automaticamente
```

Quando a pessoa futuramente criar sua conta no App 24/7 e validar o mesmo CPF:

```text
conta validada
↓
backend localiza compras anteriores elegíveis
↓
histórico passa a mostrá-las
```

O App Cliente nunca deve revelar compras antigas apenas porque alguém digitou um CPF sem validação de identidade.

---

# 11. Histórico de compras

O app deve mostrar compras vinculadas à conta.

Uma compra pode mostrar:

- data;
- horário;
- Condomínio/mercado;
- valor;
- status;
- meio de pagamento;
- quantidade de itens.

Detalhe:

```text
Pedido
Data / hora
Local
Itens
Subtotal
Descontos
Total
Pagamento
Status
Comprovante
Benefício gerado, quando aplicável
```

Não mostrar enums técnicos diretamente quando houver tradução amigável.

---

# 12. Comprovantes

No detalhe de uma compra aprovada, o cliente pode:

```text
Ver comprovante
Enviar por WhatsApp
Enviar por e-mail
Compartilhar
```

O App Cliente não gera o comprovante financeiro por conta própria.

Ele solicita ao backend os dados/ações disponíveis.

Falha no envio de comprovante não altera o status da compra.

---

# 13. Fidelidade — regra geral

A fidelidade é opcional.

O gestor da Empresa pode habilitar ou desabilitar o programa externamente.

O App Cliente apenas respeita essa configuração.

Se fidelidade estiver desativada:

- esconder pontos;
- esconder cashback;
- esconder recompensas;
- esconder cupons de fidelidade;
- não deixar espaços vazios na Home.

---

# 14. Elegibilidade para pontos e cashback

Regra definida:

> **Pontos e cashback só contam quando a compra estiver vinculada a uma conta App 24/7 elegível.**

Compra identificada somente por CPF no Terminal, sem conta vinculada:

```text
histórico futuro = SIM
pontos = NÃO
cashback = NÃO
```

Compra vinculada à conta através do fluxo do App:

```text
histórico = SIM
pontos/cashback = conforme configuração do backend
```

O App Cliente não decide sozinho se uma compra pontua.

---

# 15. Pontos

Quando habilitado, o app pode mostrar:

```text
Meus pontos
850 pts

Próxima recompensa
1000 pts

Faltam 150 pts
```

O backend entrega:

- saldo;
- movimentos;
- regra vigente;
- recompensas;
- expiração quando aplicável.

O app não recalcula pontos.

---

# 16. Cashback

Quando habilitado:

```text
Meu cashback
R$ 18,40
```

O backend entrega:

- saldo;
- movimentos;
- validade;
- regras de uso;
- elegibilidade.

O app não deve assumir que cashback pode pagar 100% da compra.

Essa regra precisa vir do backend.

---

# 17. Pontos e cashback na mesma Empresa

Ainda é decisão aberta se uma Empresa pode ter:

```text
Pontos
Cashback
Pontos + Cashback
```

Não implementar simultaneidade sem confirmação do backend/configuração.

Ver [[92-decisoes-abertas]].

---

# 18. Recompensas

O app pode exibir recompensas configuradas pelo gestor.

Exemplo:

```text
10% OFF

Custa:
500 pontos

Compra mínima:
R$ 100,00

Desconto máximo:
R$ 25,00
```

Outro exemplo:

```text
R$ 15 OFF

Custa:
400 pontos

Compra mínima:
R$ 80,00
```

O cliente deve entender claramente:

- custo em pontos;
- desconto;
- compra mínima;
- validade;
- regras principais.

---

# 19. Cupom com valor mínimo

Regra importante:

Um cupom pode exigir valor mínimo de compra.

Exemplo:

```text
10% OFF
Compra mínima: R$ 100,00
```

O App Cliente mostra essa condição antes do resgate/uso.

O Terminal/backend decide se o carrinho atual atende à regra.

O Flutter não valida o carrinho porque o carrinho não existe no celular.

---

# 20. Resgate de recompensa

Fluxo conceitual:

```text
Recompensa
↓
Trocar por 500 pontos
↓
confirmação
↓
backend realiza resgate
↓
cupom emitido
↓
cupom aparece em "Meus cupons"
```

Evitar resgate por duplo clique.

Durante request:

```text
Resgatando...
```

e botão desabilitado.

---

# 21. Cupom no App Cliente

Um cupom deve mostrar:

- benefício;
- valor mínimo da compra;
- desconto máximo quando houver;
- validade;
- status;
- regras principais.

Estados amigáveis:

```text
Disponível
Usado
Expirado
Indisponível
```

---

# 22. Uso do cupom no Terminal

O celular não aplica o cupom diretamente à compra.

Fluxo:

```text
App
↓
Meus cupons
↓
Usar no Terminal
↓
gera QR temporário
↓
scanner do Terminal
↓
backend valida
↓
Terminal recebe resultado
```

O QR não deve carregar uma regra confiável como:

```text
DESCONTO=50
```

Deve carregar token temporário.

---

# 23. Feature flags / configurações remotas

O App deve estar preparado para recursos opcionais recebidos do backend.

Exemplos conceituais:

```text
catalogoAppAtivo
promocoesAppAtivas
fidelidadeAtiva
pontosAtivos
cashbackAtivo
cuponsAtivos
```

Não necessariamente usar esses nomes.

Usar o contrato real encontrado no backend.

A UI deve se adaptar sem quebrar.

---

# 24. Estados de UI obrigatórios

As telas que carregam dados remotos devem tratar:

```text
loading
success
empty
error
refreshing
```

Exemplos:

## Sem promoções

```text
Nenhuma oferta disponível no momento.
```

## Sem compras

```text
Você ainda não possui compras no histórico.
```

## Fidelidade desativada

Não mostrar bloco vazio.

## Sem cupons

```text
Você ainda não possui cupons disponíveis.
```

---

# 25. Segurança

O App Cliente nunca deve confiar em valores manipuláveis localmente para:

- saldo;
- pontos;
- cashback;
- desconto;
- preço;
- cupom;
- status de compra;
- elegibilidade.

O backend é autoritativo.

Não armazenar secrets no app.

---

# 26. Privacidade

Dados como:

- CPF;
- telefone;
- e-mail;
- histórico de compras;

são dados pessoais.

Evitar exposição desnecessária em:

- logs;
- mensagens de erro;
- analytics;
- screenshots internos de debug.

---

# 27. Design e experiência

O App Cliente deve parecer um aplicativo para consumidor final, não um painel administrativo.

Priorizar:

- imagens de produtos;
- promoções;
- benefícios;
- histórico simples;
- navegação clara;
- pouca terminologia técnica.

Evitar mostrar:

```text
tenant
PaymentAttempt
EstoqueCondominio
PROCESSING
remoteOrderId
```

quando houver tradução de UX apropriada.

---

# 28. O que pertence ao gestor, mas NÃO a este projeto

O gestor pode configurar externamente:

- ativar/desativar fidelidade;
- escolher pontos/cashback;
- definir regra de pontos;
- definir cashback;
- criar recompensas;
- definir valor mínimo de compra;
- definir desconto máximo;
- ativar/desativar catálogo;
- ativar/desativar promoções.

> [!warning]
> Não criar essas telas de administração no App Cliente.

O App Cliente apenas consome o resultado/configuração.

---

# 29. Decisões confirmadas

- O App Cliente não realiza compras.
- O Terminal continua sendo o ponto de venda.
- A Home mostra produtos do Condomínio vinculado.
- Promoções devem receber destaque.
- Fidelidade pode ser desativada pelo gestor.
- Pontos só contam em compras vinculadas à conta App 24/7.
- Cashback só conta em compras vinculadas à conta App 24/7.
- CPF sem conta permite histórico futuro, mas não gera fidelidade.
- CPF digitado no Terminal não cria conta.
- O app gera QR temporário para identificação no Terminal.
- Cupons podem exigir valor mínimo de compra.
- O app deve mostrar o valor mínimo do cupom.
- Uso do cupom acontece no Terminal através de QR/token.
- Backend decide preço, promoção, pontos, cashback e cupom.
- Histórico e comprovantes pertencem ao App Cliente.
- Configuração do gestor é externa a este projeto.

---

# 30. Decisões ainda abertas

Registrar em [[92-decisoes-abertas]]:

- Pontos e cashback podem coexistir?
- Pontos expiram?
- Cashback expira?
- Qual duração do QR de identificação?
- Qual duração do QR de cupom?
- Cupom e promoção acumulam?
- Pode usar mais de um cupom?
- Cashback pode cobrir 100% da compra?
- Cashback possui valor mínimo para uso?
- Recompensa resgatada pode ser devolvida?
- Qual política para estorno de compra que gerou pontos/cashback?
- Como será a validação definitiva de CPF no cadastro?
- Qual regra para cliente com mais de um Condomínio?
- Como o usuário troca o Condomínio ativo?

Não decidir silenciosamente no Flutter.

---

# 31. Ordem recomendada de implementação

Primeira fase:

```text
1. Autenticação
2. Perfil
3. Condomínio vinculado
4. Home
5. Produtos do Condomínio
6. Promoções
7. Histórico
8. Detalhe de compra
9. Comprovantes
```

Segunda fase:

```text
10. QR de identificação no Terminal
11. Fidelidade
12. Pontos
13. Recompensas
14. Cupons
15. QR de cupom
```

Terceira fase:

```text
16. Cashback
17. Preferências avançadas
18. Suporte por compra
```

Adaptar conforme o que já estiver implementado no projeto real.

---

# 32. Regra de documentação para o Codex

Ao implementar uma funcionalidade:

1. localizar a nota correspondente;
2. registrar o status antes da alteração;
3. implementar no código real;
4. testar;
5. atualizar a nota com:
   - arquivos reais;
   - models;
   - services;
   - rotas;
   - estados;
   - limitações;
6. atualizar o status da nota.

Status recomendados:

```text
PLANEJADO
EM_IMPLEMENTACAO
PARCIAL
IMPLEMENTADO
REVISAR
LEGADO
```

---

# 33. Meta do projeto

O App 24/7 Cliente deve ser o ponto de relacionamento digital com o consumidor:

```text
CLIENTE
   ↓
APP 24/7
   ├── produtos
   ├── promoções
   ├── identificação
   ├── histórico
   ├── comprovantes
   ├── pontos/cashback
   └── cupons
          ↓
      uso presencial
          ↓
       TERMINAL
```

Sem duplicar o checkout e sem mover regras críticas para o celular.

> **Resumo:** o app aproxima o cliente do mercado e aumenta retenção; a compra continua presencial no Terminal.
