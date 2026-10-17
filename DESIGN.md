# Design System

## Theme strategy

- Material 3 enabled: yes
- Brightness atual: light only
- Direção aprovada: light + dark com `ThemeMode.system`, `light` e `dark`
- Platform: material_only
- Brand behavior: brand-strict, sem dynamic color substituindo o azul App247

## Color

### Seed and brand colors

- Azul principal existente: `#082F5B`
- Navy profundo existente: `#031B35`
- Fundo claro existente: `#FFFBF4`
- Ink existente: `#152236`
- Accent alvo: dourado elegante, reservado para fidelidade, recompensas e detalhes premium

### Current light roles

| Role | Value |
|---|---|
| primary | `#082F5B` |
| onPrimary | `#FFFFFF` |
| secondary | `#238B61` |
| onSecondary | `#FFFFFF` |
| tertiary | `#D94735` |
| onTertiary | `#FFFFFF` |
| surface | `#FFFFFF` |
| onSurface | `#152236` |
| outline | `#E1E6EA` |
| scaffold background | `#FFFBF4` |

O código ainda não possui scheme escuro nem dourado semântico. A implementação deve derivar papéis completos e contrastantes para ambos os temas e concentrar estados adicionais em uma `ThemeExtension`, sem espalhar literais pelas telas.

## Typography

### Family

- System stack do Flutter: Roboto no Android e equivalente do sistema nas demais plataformas.
- Uma única família para reduzir custo, preservar legibilidade e manter familiaridade Material.

### Current customized roles

| Role | Size | Weight | Height | Letter spacing |
|---|---:|---:|---:|---:|
| displaySmall | 34 | 800 | 1.08 | -1.1 |
| headlineMedium | 26 | 800 | 1.15 | -0.6 |
| titleLarge | 20 | 800 | 1.20 | -0.2 |
| titleMedium | 16 | 700 | 1.25 | default |
| bodyLarge | 16 | regular | 1.45 | default |
| bodyMedium | 14 | regular | 1.40 | default |
| labelLarge | 14 | 700 | 1.20 | default |
| labelMedium | 12 | 700 | 1.20 | 0.2 |

Os demais papéis herdam Material 3. A expansão deve preservar escala de texto e evitar estilos crus nas páginas.

## Space

### Tokens atuais

- `xxs`: 4
- `xs`: 8
- `sm`: 12
- `md`: 16
- `lg`: 24
- `xl`: 32

### Border radius

- Control: 14
- Card: 20
- Hero/sheet/dialog: 28
- Pill: somente badges e chips, não superfícies genéricas

## Elevation and surfaces

- Cards atuais usam borda sutil e elevação zero.
- Light: fundo branco quente, superfícies brancas/cinza muito claro.
- Dark: fundo navy profundo, superfícies em níveis de azul escuro; nunca preto puro.
- Sombras devem ser discretas. No dark, profundidade vem principalmente da diferença entre surfaces.

## Motion

- Short: 150 ms
- Medium: 220 ms
- Long: 360 ms
- Standard: ease out cubic
- Emphasized: ease out quart
- Exit: ease in cubic
- Usos: troca de estado, expansão, confirmação e continuidade por `AnimatedSwitcher`, `AnimatedContainer` e `Hero` quando houver relação real.
- Não usar bounce, elastic ou coreografia de entrada de página.

## Components

### Existing

- `AppPage`, `AppCard`, `SectionHeader`, `EmptyState`, `ErrorState`, `StatusBadge`, `ProductCard` e `PurchaseCard` em `lib/src/shared/app_widgets.dart`.
- Component themes em `lib/src/core/theme/app_theme.dart` para cards, botões, inputs, chips, navigation bar, dialogs e snackbars.

### Target reusable vocabulary

- Scaffold/top bar responsivos, botões primário e secundário, estados loading/empty/error, amount/status, balance, reward, coupon e QR.
- Um componente deve existir somente quando consolida regra visual ou comportamento repetido.

## Layout

- Compact abaixo de 600 dp: uma coluna e `NavigationBar`.
- Medium a partir de 600 dp: conteúdo com largura controlada e navegação adaptada quando isso melhora a tarefa.
- Conteúdo de leitura não deve se esticar indefinidamente.
- Grids devem reagir às constraints do container, não a modelos específicos de aparelho.

## Iconography and imagery

- Material Icons como conjunto único.
- Logo existente em `lib/src/content/app_logo.png`.
- Imagens de produto vêm do backend, com loading, crop previsível e fallback de erro.
- Ícones informativos precisam de contexto; ações icon-only recebem tooltip.

## Current inconsistencies to remove

- Ausência de dark theme e ThemeMode persistido.
- Uso de `Colors.white` e outros literais em widgets e no tema.
- Espaçamentos e raios one-off ainda presentes em páginas.
- Estados visuais e status distribuídos entre telas.
- Algumas telas parecem prontas, mas exibem listas vazias porque não consomem o backend.
