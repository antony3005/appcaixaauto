# Auditoria de implementação — App 24/7 Cliente

Data: 2026-09-14  
Fonte principal: [[index-00-app-cliente|INDEX-00 do App Cliente]]

## Estado original

| Área | Status original | Evidência e decisão |
|---|---|---|
| `main.dart` | LEGADO | `MaterialApp` direto, tema azul padrão e deep link levando para carrinho. |
| Router | AUSENTE | Navegação imperativa espalhada com `MaterialPageRoute`. |
| Tema / `ColorScheme` | PARCIAL | `primarySwatch` e cores literais por widget; sem Material 3 consolidado. |
| State management | AUSENTE | Nenhum mecanismo de estado de aplicação. |
| DI | AUSENTE | Nenhuma injeção existente. |
| HTTP client | AUSENTE | Nenhum cliente de API. |
| Services / repositories | AUSENTE | Nenhuma camada de acesso a dados. |
| Models | AUSENTE | Nenhum modelo de domínio Flutter. |
| Autenticação | PARCIAL / REVISAR | Formulário apenas com CPF, validação local, sem senha/API e com CPF impresso no log. |
| Perfil | AUSENTE | Não havia tela ou consumo de dados. |
| Home | LEGADO | Simulava carteira, Pix, saldo e envio de dinheiro; incompatível com o App Cliente. |
| Navegação | LEGADO | Drawer com Home e Carrinho. |
| Carrinho / checkout | LEGADO | Tela com “Finalizar compra”; proibida neste app. |
| Catálogo do condomínio | AUSENTE | Nenhuma tela nem vínculo de Condomínio. |
| Promoções | AUSENTE | Nenhuma tela/contrato consumido. |
| Histórico | AUSENTE | Nenhuma tela, embora exista listagem básica no backend. |
| Comprovantes | AUSENTE | Nenhuma integração. |
| QR de identificação | AUSENTE | Deep link existente era de sessão de checkout, não identificação do cliente. |
| Fidelidade / pontos / cashback | AUSENTE | Sem modelos, configuração ou endpoints cliente no backend. |
| Recompensas / cupons | AUSENTE | Sem modelos, configuração ou endpoints cliente no backend. |
| Shared widgets | PARCIAL / LEGADO | App bar e drawer específicos do protótipo, sem estados reutilizáveis. |
| Testes | LEGADO | Teste padrão do contador, incompatível com o app real. |

## Contratos backend confirmados

- `POST /auth/login`: recebe `cpf` e `senha`; retorna `token` e `user`.
- `GET /user/{userId}`: retorna perfil, mas não informa o Condomínio vinculado.
- `PUT /user/{id}`: altera campos do perfil; contrato atual também aceita `ativo`, exigindo revisão de autorização.
- `GET /user/{userId}/orders`: histórico paginado básico com `orderId`, `status`, `subtotal`, `desconto`, `total` e `createdAt`.
- `POST /comprovante`: envia comprovante por canal, mas exige `terminalId`, ausente no item do histórico cliente.
- `GET /terminais/{terminalId}/produtos-disponiveis`: catálogo contextual do Terminal/Condomínio com preços promocionais calculados pelo backend, mas o perfil cliente não fornece `terminalId` nem um contrato próprio de catálogo.

## Decisões de implementação

- Remover integralmente o fluxo legado de carrinho/checkout e seus deep links.
- Preservar a ausência de framework de estado externo: usar `ChangeNotifier` do Flutter e injeção explícita por construtor.
- Introduzir um único cliente HTTP e um repository, sem Dio, Riverpod, Bloc, Provider, GetX ou GoRouter.
- Consumir apenas login, perfil e histórico básico, únicos contratos utilizáveis com a identidade retornada.
- Preparar os modelos e componentes de catálogo, promoção, compra detalhada, fidelidade, recompensas, cupons e QR sem dados mockados em produção.
- Ocultar domínios opcionais quando o backend não entrega configuração/capacidade.
- Registrar contratos ausentes em `docs/backend-gaps-app-cliente.md`.

## Design system

Direção: aplicativo de mercado de proximidade, acolhedor e simples; não dashboard.

- Azul profundo: identidade e navegação.
- Verde-fresco: disponibilidade, identificação e fidelidade.
- Coral: ofertas, usado com parcimônia.
- Fundo marfim e superfícies claras: sensação de consumo cotidiano.
- Escala de spacing de 4 a 32, raios por função e elevação discreta.
- Material 3 com temas de botão, input, card, chip, navigation bar, dialog e snackbar.

## Limite da auditoria

Nenhuma alteração foi feita no backend de referência, no Terminal Python, FastAPI, n8n, Mercado Pago ou painel do gestor.
