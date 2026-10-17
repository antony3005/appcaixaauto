# App247 Client Design System

Identidade premium e tecnológica: azul App247 protagonista, dourado restrito a valor e recompensa, dark navy sem preto puro e light branco azulado.

## Tokens

| Token | Valor | Uso |
|---|---|---|
| Primary navy | `#082F5B` | Marca, ação e hierarquia |
| Supporting blue | `#146CC5` | Interação |
| Dark background | `#031B35` | Fundo dark |
| Dark surface | `#0B2847` | Cards dark |
| Light background | `#F7F9FC` | Fundo light branco azulado |
| Light surface | `#FCFDFE` | Cards light |
| Gold accent | `#C89B3C` | Pontos, cashback e recompensa |
| Success | `#238B61` | Aprovação/disponibilidade |
| Error | `#C94B3A` | Falha/cancelamento |

`AppSemanticColors` resolve gold, success, warning, muted e QR conforme o brilho.

## Tipografia, layout e movimento

- Escala Material 3 customizada de 12–34 px; títulos 700–800; corpo 14–16 px.
- Text scaling do sistema preservado.
- Spacing: 4/8/12/16/24/32/48 dp.
- Radius: 10/14/20/28/pill. Pill fica restrito a badges e chips; CTAs usam raio de controle.
- Touch target mínimo: 48 dp; conteúdo máximo: 720 dp.
- Movimento: 150/220/360 ms, `easeOutCubic/easeOutQuart`, Hero contextual e skeleton discreto.

## Componentes

`AppContent`, `AppCard`, `SectionHeader`, `EmptyState`, `ErrorState`, `LoadingSection`, `LoadingTile`, `StatusChip`, `PurchaseCard`, `ProductCard`, além de heroes de identidade, saldo, recompensa, cupom e QR. `AppCard` possui variantes `standard`, `highlight`, `interactive` e `premium`, evitando uma única superfície genérica para toda a interface.

Para leitura por scanner, `qrPaper` e `qrInk` são tokens dedicados e mantêm contraste independente do tema.

Light usa superfícies claras, texto navy e azul protagonista. Dark usa navy profundo, superfícies azul-escuras e texto off-white. System segue o aparelho. O QR mantém branco e módulos escuros para escaneabilidade.

A navegação top-level usa `NavigationBar` Material 3 em uma superfície flutuante com quatro destinos no máximo. Home combina identidade, fidelidade e QR em um único hero; atalhos standard e premium não repetem a mesma hierarquia visual.
