# Design System — 24/7 App Cliente

Fonte: design system **24/7** (artifact `claude.ai/artifact/7ZxL67erZA3M6bRbCGgjSP`). Este arquivo descreve como ele está implementado no Flutter. Tokens em `lib/src/core/theme/app_theme.dart`, componentes em `lib/src/shared/app_widgets.dart`.

**O app identifica, informa e recompensa. O Terminal vende.**

## Princípios

1. **Meu QR primeiro.** O tile navy do Início e a aba Meu QR estão sempre a um toque.
2. **Azul gera confiança, dourado sinaliza valor.** Navy e `primary` para identidade e ações; dourado só para pontos, recompensas e cupons.
3. **Dados reais, estados honestos.** Esqueleto ou loader enquanto carrega, estados de vazio e erro claros, nunca conteúdo inventado.
4. **Hierarquia calma.** Números grandes, rótulos curtos, espaço generoso; um botão principal por tela.

Evitar: carrinho, checkout ou "comprar" (o catálogo só informa); dourado em botões ou como texto sobre fundo claro; gradientes e brilhos; preto puro no escuro; emoji como ícone.

## Tema

- Material 3, claro + escuro com `ThemeMode.system`, `light` e `dark` (escolha salva em `ThemeController`).
- Sem dynamic color: a marca é fixa.
- Localização Material em pt-BR (`flutter_localizations`).

## Cor

| Token | Claro | Escuro | Uso |
|---|---|---|---|
| background | `#FFFFFF` | `#031B35` | Fundo da página. Conteúdo direto sobre ele. |
| surface | `#FCFDFE` | `#0B2847` | Barra inferior, folhas, diálogos. |
| surface-low | `#F4F7FB` | `#07223D` | Poço de foto do produto, busca, resumo de totais. |
| surface-container | `#EEF3F8` | `#0B2847` | Esqueletos. |
| surface-high | `#E7EDF4` | `#123553` | Poços de ícone. |
| ink | `#10243B` | `#F4F7FB` | Texto. |
| muted | `#607389` | `#A9B9CA` | Texto secundário, sublinhado dos campos (4,6:1). |
| outline | `#DCE4EE` | `#234563` | Divisores de 1px (decorativo). |
| primary | `#082F5B` | `#78B7F4` | Botão principal, links, chip selecionado, foco. |
| primary-soft | `#DCEBFA` | `#244D72` | Item ativo da navegação, avisos informativos. |
| navy | `#082F5B` | igual | Cabeçalhos de marca, tile do Meu QR, abertura. |
| gold / gold-container | `#C89B3C` / `#F8EFD9` | `#E0B75F` / `#493B20` | Pontos e recompensas. Texto sobre ele em `on-gold`. |
| success / warning / error | `#238B61` / `#855600` / `#BA1A1A` | `#72D5A6` / `#FFC86A` / `#FFB4A9` | Sempre com ícone ou palavra junto. |
| qr-paper / qr-ink | `#FDFEFF` / `#031B35` | igual | O QR fica escuro sobre branco nos dois temas. |

Cores fixas da marca em `AppColors`; as que mudam com o tema em `AppSemanticColors` (`context.semantic`) e no `ColorScheme`.

## Tipografia

**Plus Jakarta Sans** embarcada em `assets/fonts` (400–800, licença OFL). Escala no `TextTheme`:

| Papel DS | Flutter | Tamanho / peso |
|---|---|---|
| display | `displaySmall` | 32 / 800, -0,8 |
| headline | `headlineSmall` | 24 / 800, -0,4 |
| title-large | `titleLarge` | 20 / 800, -0,3 |
| title-medium | `titleMedium` | 16 / 700 |
| title-small | `titleSmall` | 14 / 700 |
| price | `context.priceStyle` | 22 / 800 |
| body-large / body / body-small | `bodyLarge` / `bodyMedium` / `bodySmall` | 16 / 14 / 12 (small em `muted`) |
| button | `labelLarge` | 13 / 800, +0,6, rótulos em CAIXA ALTA |
| label | `labelMedium` | 12 / 700 |
| eyebrow | `labelSmall` (`context.eyebrowStyle`) | 10 / 800, +0,8, caixa alta |

O texto acompanha a escala do sistema; só a placa "24/7" (logotipo) não escala.

## Espaço, forma e profundidade

- Espaço: `AppSpacing.s1` 4 · `s2` 8 · `s3` 12 · `s4` 16 · `s5` 20 · `s6` 24 · `s8` 32 · `s10` 40. Margem `gutter` 16, seções `section` 24.
- Coluna de conteúdo: `AppContent`, máx. 480px, centralizada.
- Raios: `xs` 6 (selos), `sm` 12 (poços, fotos), `md` 16 (avisos, blocos), `lg` 24 (cartões de destaque, QR, folhas, cantos dos cabeçalhos), `pill` (botões, chips).
- Profundidade quase nenhuma: `cardShadow` só no par de destaque; `raisedShadow` na barra inferior e no cartão do QR. No escuro, contorno em vez de sombra.
- Toque mínimo de 48dp.

## Telas

- **Planas por padrão:** página branca, seções separadas por espaço, títulos `titleMedium` e divisores de 1px. Sem um card por linha, sem card dentro de card.
- **Telas de marca** (Abertura, Boas-vindas, Login, Meu QR, Perfil) abrem com `BrandHeader` navy e cantos inferiores `lg`.
- **Barra superior** (`AppTopBar`): voltar em círculo com contorno · título `titleLarge` · uma ação.
- **Navegação inferior** (`AppNavigationBar`): Início · Catálogo · Meu QR · Compras. As abas só são construídas quando abertas. Perfil abre pelo avatar no Início; Benefícios pelo cartão de pontos e pelos atalhos.
- O lembrete "O app identifica, informa e recompensa. O Terminal vende." aparece no Login, Início, Meu QR e detalhe do produto.

## Componentes (`app_widgets.dart`)

`AppContent`, `AppTopBar`, `AppIconButton`, `BrandMark`, `BrandLockup`, `BrandHeader`, `SectionHeader`, `Notice` (info, success, warning, error, gold), `IconWell`, `AppListRow`, `ListGroup`, `InfoRow`, `AppTag`, `StatusDot` / `StatusChip`, `PointsCard`, `QrTile`, `NavyAvatar`, `PrimaryButton` (com loader de pontos; variante navy), `SecondaryButton` (variante destrutiva), `AppFilterChip`, `AppSegmented`, `AppNavigationBar`, `AppSpinner`, `DotsLoader`, `Skeleton`, `LoadingSection`, `EmptyState`, `ErrorState`, `PurchaseCard` / `PurchaseList`, `ProductCard`, `ProductImage`, `OfferBadge`, `OrderSummary`.

Campos de texto: só o sublinhado (`muted` 1px; 2px `primary` no foco; 2px `error` no erro), rótulo sempre visível acima e ícone à esquerda; a busca do catálogo é a exceção (pílula preenchida `surface-low`).

## Movimento

- `AppAnimations`: toque 120ms, curto 150ms, médio 220ms, longo 360ms; entrada `easeOutCubic` / `easeOutQuart`, saída `easeInCubic`.
- Loaders pequenos: círculo para página, pontos dentro do botão, esqueletos nas listas. Com "remover animações" ativo, eles desaceleram para 3s.
- Sem bounce no conteúdo e sem coreografia de entrada de página.

## Verificação

- `test/visual_screenshots_test.dart` gera as capturas em `docs/screenshots/{light,dark}` com a fonte real.
- `test/text_scale_test.dart` percorre os fluxos principais em 360×740 com texto em 100% e 200% e falha se houver overflow.
