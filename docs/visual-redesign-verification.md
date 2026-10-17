# Verificação visual do redesign — App247 Cliente

Data: **03/10/2026**

## Método e limitações da auditoria

A auditoria começou antes de qualquer alteração de código. `flutter devices` encontrou Linux e Chrome; o projeto não possui target Linux. `flutter run -d chrome --web-port 7357` iniciou o app em modo debug. O único AVD Android instalado não iniciou porque exige aproximadamente 7,4 GB livres e o ambiente tinha aproximadamente 3,1 GB. A instância Chrome não estava exposta à automação desta sessão e o backend local respondeu `HTTP 000` em `localhost:8080`.

Por isso, a validação autenticada foi feita com páginas e rotas reais de produção, usando fixtures somente em testes. O teste de matriz entra pelo `App247Client`, autentica pela UI e toca nos mesmos controles usados no app. Nenhum dado demonstrativo foi incluído no runtime.

O material visual anterior também não podia ser aceito sem revisão: `docs/screenshots/light/cupons.png` estava praticamente vazio e capturas sequenciais conservavam frames residuais, inclusive uma AppBar duplicada no detalhe da compra. O capturador passou a desmontar a rota anterior antes de cada frame; Recompensas e Cupons agora renderizam os destinos focados realmente abertos pela Home. As capturas foram regeneradas e inspecionadas novamente.

## Divergências encontradas antes da correção

- Home ainda era uma sequência de cabeçalho, dois cards, grade uniforme e cards de produto; a mudança estrutural era pequena.
- Login tinha hero azul, mas o restante ainda parecia um formulário Material genérico.
- O dark mode usava azul claro excessivo na fidelidade e mantinha inconsistências de contraste em superfícies premium.
- Compras ficava visualmente vazia quando havia poucos registros.
- Perfil começava com uma linha simples de avatar e dados, sem identidade visual forte.
- Recompensas usavam o mesmo card branco de outras áreas.
- Atalhos de Cupons e Recompensas apenas mudavam para o topo da aba Benefícios, sem abrir o conteúdo pretendido.
- As capturas da Home omitiam a navegação inferior porque renderizavam `HomePage` isoladamente.
- A suíte não provava os caminhos completos até Cadastro, Recuperação, Produto, Comprovante, Suporte, QR de cupom, Preferências e Aparência.
- Ainda havia cores literais, `TextStyle` cru e valores visuais avulsos fora do tema.

## Matriz real de navegação depois da correção

| Origem | Ação | Destino esperado | Destino atual | Funciona? |
|---|---|---|---|---|
| Login | Cadastre-se | Cadastro | `RegistrationPage` | Sim, teste pela UI |
| Login | Esqueci minha senha | Recuperação | `PasswordRecoveryPage` | Sim, teste pela UI |
| Login/bootstrap | conta sem condomínio | Tenant Link | estado dedicado no `ClientShell` | Sim, teste de estado |
| Home | Meu QR | Identificação | `CustomerIdentificationPage` | Sim, teste pela UI |
| Home | Catálogo | Catálogo | `CatalogPage` | Sim, teste pela UI |
| Catálogo | produto | Detalhe do produto | `ProductDetailPage` | Sim, teste pela UI |
| Home | Compras | Histórico | aba `PurchasesPage` | Sim, teste pela UI |
| Compras | card | Detalhe da compra | `PurchaseDetailPage` | Sim, teste pela UI |
| Detalhe | Ver comprovante | Viewer | `ReceiptPage` | Sim, teste pela UI |
| Detalhe | Preciso de ajuda | Suporte | formulário de suporte | Sim, teste pela UI |
| Home | Recompensas | Recompensas | `BenefitsPage(focus: rewards)` | Sim, teste pela UI |
| Home | Cupons | Meus cupons | `BenefitsPage(focus: coupons)` | Sim, teste pela UI |
| Benefícios | Trocar | Confirmação/resgate | diálogo e atualização do controller | Sim, teste de interação |
| Cupom disponível | Usar no Terminal | QR do cupom | `TemporaryQrPage.coupon` | Sim, teste pela UI |
| Perfil | Preferências | Preferências | `PreferencesPage` | Sim, teste pela UI |
| Perfil | Tema | Aparência | seletor Sistema/Claro/Escuro | Sim, teste pela UI |

## Home

Antes:

- cabeçalho discreto separado dos cards;
- fidelidade e QR pareciam widgets independentes;
- quatro atalhos repetiam a mesma composição;
- screenshot não mostrava a navegação real.

Depois:

- hero navy contínuo reúne saudação, condomínio, avatar, fidelidade e QR;
- fidelidade usa superfície premium e dourado somente como sinal de valor;
- QR tem peso equivalente de ação e chave estável de navegação;
- atalhos standard e premium têm hierarquia, ícones circulares e direção explícita;
- Home light e dark agora são capturadas dentro do `ClientShell`, com navegação inferior real;
- catálogo, rewards e compras permanecem condicionados às capabilities do backend.

Como acessar: autenticar-se com condomínio vinculado.

Screenshots: `docs/screenshots/light/home.png`, `docs/screenshots/dark/home.png`.

## Login, Cadastro e Recuperação

Antes:

- branding e formulário tinham pouca continuidade;
- a entrega anterior não comprovava a navegação completa.

Depois:

- login ganhou hero mais alto, proposta de valor e indicadores visuais de QR, Compras e Benefícios;
- campos, recuperação, CTA e cadastro continuam visíveis na primeira experiência;
- Cadastro mantém agrupamento, validações e termos sem alterar o contrato;
- Recuperação mantém CPF → código → nova senha → sucesso com progressão visual;
- testes partem do Login e abrem Cadastro e Recuperação pelos controles reais.

Screenshots: `light/login.png`, `dark/login.png`, `light/cadastro.png`, `light/recuperacao.png`.

## Tenant Link e Meu QR

Depois:

- Tenant Link preserva hero contextual, colagem, loading, erro e atualização;
- Meu QR usa navy fixo nos dois temas para manter identidade e contraste;
- QR permanece isolado em papel claro, com countdown, regeneração e aviso de privacidade.

Como acessar: conta sem condomínio; Home → Meu QR.

Screenshots: `light/tenant-link.png`, `light/meu-qr.png`.

## Catálogo e Produto

Depois:

- busca, categorias horizontais e paginação continuam ligados ao backend;
- cards ganharam rótulo de categoria mais claro, badge de oferta e cores semânticas por tema;
- detalhe mantém imagem dominante, disponibilidade, preço, promoção, unidade e descrição;
- não há carrinho, Comprar ou checkout.

Como acessar: Home → Catálogo → produto.

Screenshots: `light/catalogo.png`, `light/produto.png`.

## Compras, Detalhe, Comprovante e Suporte

Depois:

- histórico ganhou hero com quantidade aprovada e total calculado apenas a partir dos dados carregados;
- cards mantêm data, valor, status, itens e chevron;
- detalhe, viewer PNG, compartilhamento/envio e suporte continuam conectados;
- a matriz automatizada percorre Compras → Detalhe → Comprovante e Detalhe → Suporte.

Screenshots: `light/compras.png`, `light/detalhe-compra.png`, `light/comprovante.png`, `light/suporte.png`.

## Benefícios, Recompensas e Cupons

Depois:

- saldo permanece real para POINTS/CASHBACK e ausente em NONE;
- recompensa usa uma superfície premium distinta, custo, regra, validade e CTA de resgate;
- Cupons e Recompensas agora têm destinos focados quando abertos pela Home;
- o QR temporário de cupom é alcançado por `Usar no Terminal` em teste de rota real.

Screenshots: `light/beneficios.png`, `dark/beneficios.png`, `light/recompensas.png`, `light/resgate.png`, `light/cupons.png`, `light/qr-cupom.png`.

## Perfil, Preferências e Aparência

Depois:

- perfil ganhou hero de identidade navy e organização mais clara entre conta e configurações;
- Preferências continua usando somente e-mail e WhatsApp reais;
- Aparência altera Sistema/Claro/Escuro imediatamente;
- ambos os destinos são abertos pela UI no teste de matriz.

Screenshots: `light/perfil.png`, `dark/perfil.png`, `light/preferencias.png`, `light/aparencia.png`.

## Figma

Arquivo `7PbgjdrUr759AkoqMjNVeY`, página `0:1`.

| Frame | Node ID | Adaptação |
|---|---|---|
| Login | `2:6020` | bloco de marca e separação forte do formulário |
| Cadastro | `2:6067` | hierarquia e ritmo do formulário |
| Início | `2:6123` | hero, atalhos, ofertas e recentes |
| Meu QR | `2:6220` | QR como foco de alto contraste |
| Catálogo | `2:6733` | busca, categorias e grid |
| Detalhe do produto | `2:6823` | imagem dominante e hierarquia de preço |
| Compras | `2:6886` | leitura rápida do histórico e status |
| Detalhe da compra | `2:6997` | status, itens, resumo e ações |

O MCP oficial foi chamado novamente nesta auditoria, mas a conta Starter respondeu com limite de chamadas atingido. Os node IDs acima foram confirmados na documentação existente do projeto; não foi alegada uma nova leitura dos frames. A paleta lima e qualquer compra mobile continuam descartadas.

## Aplicação concreta da impeccable-flutter

- registro product e estratégia Material-only confirmados antes da edição;
- hero da Home redesenhado como composição única, não grade de cards idênticos;
- botões principais deixaram de usar pill indiscriminadamente; pill ficou restrito a badges/chips;
- navegação Material 3 recebeu superfície flutuante, contorno e destino selecionado claro;
- light usa branco azulado e texto navy; dark usa navy profundo, sem preto puro;
- `Colors.white/white70` e `TextStyle` crus encontrados na auditoria foram removidos das telas;
- tokens de spacing/radius substituíram valores avulsos encontrados;
- dourado foi limitado a fidelidade, recompensa, cupom e pequenos sinais premium;
- touch targets, text scaling, Semantics, loading/error/empty e estados expirados foram preservados;
- rotas ganharam chaves e testes que simulam a ação real do usuário.

## Tabela final

| Tela | Arquivo | Como acessar | Funciona | Screenshot |
|---|---|---|---|---|
| Login | `features/auth/login_page.dart` | abrir sem sessão | Sim | `light/login.png` |
| Cadastro | `features/auth/registration_page.dart` | Login → Cadastre-se | Sim | `light/cadastro.png` |
| Recuperação | `features/auth/password_recovery_page.dart` | Login → Esqueci minha senha | Sim | `light/recuperacao.png` |
| Tenant Link | `features/shell/client_shell.dart` | conta sem condomínio | Sim | `light/tenant-link.png` |
| Home | `features/home/home_page.dart` | login válido | Sim | `light/home.png` |
| Meu QR | `features/qr/customer_identification_page.dart` | Home → Meu QR | Sim | `light/meu-qr.png` |
| Catálogo | `features/catalog/catalog_pages.dart` | Home → Catálogo | Sim | `light/catalogo.png` |
| Produto | `features/catalog/catalog_pages.dart` | Catálogo → produto | Sim | `light/produto.png` |
| Compras | `features/purchases/purchases_page.dart` | aba Compras | Sim | `light/compras.png` |
| Detalhe compra | `features/purchases/purchases_page.dart` | Compras → card | Sim | `light/detalhe-compra.png` |
| Comprovante | `features/purchases/purchases_page.dart` | Detalhe → Ver comprovante | Sim | `light/comprovante.png` |
| Suporte | `features/purchases/purchases_page.dart` | Detalhe → Preciso de ajuda | Sim | `light/suporte.png` |
| Benefícios | `features/benefits/benefits_page.dart` | aba Benefícios | Sim | `light/beneficios.png` |
| Recompensas | `features/benefits/benefits_page.dart` | Home → Recompensas | Sim | `light/recompensas.png` |
| Resgate | `features/benefits/benefits_page.dart` | Recompensa → Trocar | Sim | `light/resgate.png` |
| Cupons | `features/benefits/benefits_page.dart` | Home → Cupons | Sim | `light/cupons.png` |
| QR cupom | `features/qr/temporary_qr_page.dart` | Cupom → Usar no Terminal | Sim | `light/qr-cupom.png` |
| Perfil | `features/profile/profile_page.dart` | aba Perfil | Sim | `light/perfil.png` |
| Preferências | `features/profile/profile_page.dart` | Perfil → Preferências | Sim | `light/preferencias.png` |
| Aparência | `features/profile/profile_page.dart` | Perfil → Tema | Sim | `light/aparencia.png` |

Os caminhos de screenshot são relativos a `docs/screenshots/`.
