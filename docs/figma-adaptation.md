# Adaptação do Figma

O MCP oficial do Figma inspecionou o arquivo `7PbgjdrUr759AkoqMjNVeY`, página `0:1`.

| Frame | Node ID |
|---|---|
| Login | `2:6020` |
| Cadastro | `2:6067` |
| Início | `2:6123` |
| Meu QR | `2:6220` |
| Catálogo | `2:6733` |
| Detalhe do produto | `2:6823` |
| Compras | `2:6886` |
| Detalhe da compra | `2:6997` |

## Aproveitado

- hierarquia direta de título, contexto e ação;
- cards compactos, respiro e agrupamento;
- QR isolado como foco;
- grid de catálogo e imagem dominante no detalhe;
- navegação curta e densidade moderada;
- ícones consistentes.

## Descartado

- verde-limão, por conflitar com o azul App247;
- cópia literal, pois flags e dados são reais;
- tabs incompatíveis com Início/Compras/Benefícios/Perfil;
- qualquer CTA de compra/pagamento mobile;
- dados demonstrativos sem endpoint.

O ritmo visual foi traduzido para tokens Flutter próprios. Azul permaneceu primário, navy estruturou dark mode e dourado ficou restrito a fidelidade. O resultado é mais sóbrio e próprio, alinhado a “o App identifica, informa e recompensa; o Terminal vende”.

## Verificação de 03/10/2026

O MCP oficial foi invocado novamente para a página `0:1`, mas respondeu com limite de chamadas do plano Starter. Portanto, esta revisão não declara uma nova leitura do arquivo: reutiliza somente os node IDs já documentados acima e registra a limitação em `visual-redesign-verification.md`.

A segunda adaptação tornou a referência perceptível principalmente em `Início`: hero contínuo, composição assimétrica entre fidelidade e QR, atalhos com pesos distintos, navegação curta visível e seções com ritmos diferentes. Login, Compras, Recompensas e Perfil também ganharam composição própria em vez de uma sucessão uniforme de cards.
