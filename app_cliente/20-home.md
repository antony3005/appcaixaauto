---
status: PARCIAL
ultima_revisao: 2026-09-14
---
# Home

Voltar para [[index-00-app-cliente]]. Relacionada a [[21-produtos-condominio]], [[23-promocoes]], [[30-historico-compras]] e [[40-fidelidade-visao-geral]].

## Implementação

- Tela: `lib/src/features/home/home_page.dart`.
- Estado: `ClientController` mantém dados existentes durante refresh e apresenta erro local.
- Ordem: saudação/Condomínio, ofertas, fidelidade, produtos e últimas compras.
- Seções opcionais são removidas conforme `ClientCapabilities`; não há cards vazios.
- Refresh usa uma operação de bootstrap, evitando cascata iniciada pela UI.

## Limitação

O backend não fornece bootstrap, Condomínio nem flags. Em produção a Home apresenta apenas perfil e histórico básico. Ver `docs/backend-gaps-app-cliente.md`.
